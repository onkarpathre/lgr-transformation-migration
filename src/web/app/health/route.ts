import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";
export async function GET() {
  try {
    const origin = new URL(process.env.API_ORIGIN?.trim() ?? "");
    if ((process.env.NODE_ENV === "production" && origin.protocol !== "https:") || origin.pathname !== "/") throw new Error("invalid_origin");
    const response = await fetch(new URL("/health/ready", origin), { cache: "no-store", signal: AbortSignal.timeout(5000) });
    return NextResponse.json({ status: response.ok ? "Healthy" : "Unavailable" }, { status: response.ok ? 200 : 503, headers: { "Cache-Control": "no-store" } });
  } catch { return NextResponse.json({ status: "Unavailable" }, { status: 503, headers: { "Cache-Control": "no-store" } }); }
}
