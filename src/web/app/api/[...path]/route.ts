import { NextRequest, NextResponse } from "next/server";
import { buildApiRequestHeaders } from "@/lib/request-security";

const allowedRoots = new Set(["applications", "azure-targets", "customers", "dashboard", "discovery-imports", "ip-addresses", "lookups", "migration-decisions", "projects", "readiness", "runbooks", "servers", "subnets", "v1", "waves"]);
const prohibitedHeaders = ["x-customer-id", "x-user-name", "x-lgr-test-principal", "x-principal-id", "x-roles", "x-project-roles", "x-permissions", "cookie", "forwarded", "x-forwarded-for", "x-forwarded-host", "x-forwarded-proto"];
const forwardedHeaders = ["authorization", "x-project-id", "content-type", "accept", "if-match", "if-none-match", "traceparent", "tracestate"];
const responseHeaders = ["content-type", "etag", "x-correlation-id", "traceparent", "www-authenticate"];
const allowedMethods = new Set(["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]);
const maximumBodyBytes = 26214400 + 65536;
const localTestPrincipalSetting = ["NEXT", "PUBLIC", "LGR", "TEST", "PRINCIPAL"].join("_");
type Context = { params: Promise<{ path: string[] }> };

function traceParent(): { header: string; traceId: string } {
  const bytes = new Uint8Array(24); crypto.getRandomValues(bytes);
  const hex = Array.from(bytes, value => value.toString(16).padStart(2, "0")).join("");
  return { header: `00-${hex.slice(0, 32)}-${hex.slice(32)}-01`, traceId: hex.slice(0, 32) };
}

function apiOrigin(): URL {
  const configured = process.env.API_ORIGIN?.trim() ?? "";
  let origin: URL;
  try { origin = new URL(configured); } catch { throw new Error("API_ORIGIN is invalid."); }
  if ((process.env.NODE_ENV === "production" && origin.protocol !== "https:") || origin.username || origin.password || origin.pathname !== "/" || origin.search || origin.hash) throw new Error("API_ORIGIN is not an approved origin.");
  return origin;
}

async function forward(request: NextRequest, context: Context) {
  const { path } = await context.params;
  if (!allowedMethods.has(request.method) || path.length === 0 || !allowedRoots.has(path[0]) || path.some(segment => !segment || segment === "." || segment === ".." || segment.includes("\\"))) return NextResponse.json({ title: "Request denied." }, { status: 404 });
  const contentLength = Number(request.headers.get("content-length") ?? "0");
  if (!Number.isFinite(contentLength) || contentLength < 0 || contentLength > maximumBodyBytes) return NextResponse.json({ title: "Request is too large." }, { status: 413 });
  const configuredTestPrincipal = process.env.NODE_ENV === "development" ? process.env[localTestPrincipalSetting] : undefined;
  const headers = buildApiRequestHeaders(request.headers, process.env.NODE_ENV, configuredTestPrincipal, forwardedHeaders, prohibitedHeaders);
  const trace = traceParent();
  if (!/^00-[0-9a-f]{32}-[0-9a-f]{16}-0[01]$/.test(headers.get("traceparent") ?? "")) headers.set("traceparent", trace.header);
  let body: ArrayBuffer | undefined;
  if (!["GET", "HEAD", "OPTIONS"].includes(request.method)) {
    body = await request.arrayBuffer();
    if (body.byteLength > maximumBodyBytes) return NextResponse.json({ title: "Request is too large." }, { status: 413 });
  }
  const target = new URL(`/api/${path.map(encodeURIComponent).join("/")}${request.nextUrl.search}`, apiOrigin());
  try {
    const upstream = await fetch(target, { method: request.method, headers, body, redirect: "manual", cache: "no-store", signal: AbortSignal.timeout(body ? 120000 : 30000) });
    const safeHeaders = new Headers({ "Cache-Control": "no-store" });
    responseHeaders.forEach(name => { const value = upstream.headers.get(name); if (value) safeHeaders.set(name, value); });
    if (!safeHeaders.has("x-correlation-id")) safeHeaders.set("x-correlation-id", trace.traceId);
    return new NextResponse(upstream.body, { status: upstream.status, headers: safeHeaders });
  } catch { return NextResponse.json({ title: "The service is temporarily unavailable." }, { status: 503, headers: { "Cache-Control": "no-store" } }); }
}

export const dynamic = "force-dynamic";
export const GET = forward; export const HEAD = forward; export const POST = forward; export const PUT = forward; export const PATCH = forward; export const DELETE = forward; export const OPTIONS = forward;
