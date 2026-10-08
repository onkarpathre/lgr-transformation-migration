import { NextRequest, NextResponse } from "next/server";
import { buildContentSecurityPolicy } from "@/lib/request-security";

export function proxy(request: NextRequest) {
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
  const csp = buildContentSecurityPolicy(nonce, process.env.NODE_ENV);
  const requestHeaders = new Headers(request.headers); requestHeaders.set("x-nonce", nonce); requestHeaders.set("Content-Security-Policy", csp);
  const response = NextResponse.next({ request: { headers: requestHeaders } });
  response.headers.set("Content-Security-Policy", csp); response.headers.set("X-Content-Type-Options", "nosniff"); response.headers.set("Referrer-Policy", "no-referrer"); response.headers.set("Permissions-Policy", "camera=(), microphone=(), geolocation=(), payment=(), usb=()"); response.headers.set("X-Frame-Options", "DENY"); response.headers.set("Cache-Control", "no-store");
  if (process.env.NODE_ENV === "production") response.headers.set("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
  return response;
}

export const config = { matcher: [{ source: "/((?!_next/static|_next/image|favicon.ico).*)", missing: [{ type: "header", key: "next-router-prefetch" }] }] };
