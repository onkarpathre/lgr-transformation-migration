import { render, screen, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ApiError, ApiProvider, useApi } from "@/components/ApiContext";

const json = (body: unknown, status = 200, headers: Record<string, string> = {}) => new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json", ...headers } });

function Probe() {
  const { api, apiResponse, hasPermission } = useApi();
  return <><span>{hasPermission("sql.inventory.read") ? "SQL visible" : "SQL hidden"}</span><button onClick={() => void apiResponse<{ ok: boolean }>("/api/v1/test").then(result => document.body.dataset.etag = result.etag ?? "")}>Request</button><button onClick={() => void api("/api/v1/fail").catch(error => document.body.dataset.error = `${(error as ApiError).status}:${(error as ApiError).errorCode}`)}>Fail</button></>;
}

describe("central API context", () => {
  beforeEach(() => {
    vi.stubGlobal("fetch", vi.fn((input: string | URL) => {
      const url = input.toString();
      if (url.endsWith("/api/customers")) return Promise.resolve(json([{ id: "c", name: "Council" }]));
      if (url.endsWith("/api/projects")) return Promise.resolve(json([{ id: "p", name: "Programme" }]));
      if (url.endsWith("/api/v1/session/capabilities")) return Promise.resolve(json({ permissions: ["sql.inventory.read"] }));
      if (url.endsWith("/api/v1/fail")) return Promise.resolve(json({ detail: "Changed elsewhere.", errorCode: "stale_version", correlationId: "corr" }, 412));
      return Promise.resolve(json({ ok: true }, 200, { ETag: '"version"' }));
    }));
  });

  it("derives permission-aware exposure from the server capability response", async () => {
    render(<ApiProvider><Probe /></ApiProvider>); await screen.findByText("SQL visible");
  });

  it("uses no-store and never sends caller-owned customer, role or actor headers", async () => {
    render(<ApiProvider><Probe /></ApiProvider>); await screen.findByText("SQL visible");
    const calls = vi.mocked(fetch).mock.calls; const init = calls.find(call => call[0].toString().endsWith("/api/v1/session/capabilities"))?.[1] as RequestInit; const headers = new Headers(init.headers);
    expect(init.cache).toBe("no-store"); expect(headers.has("X-Project-Id")).toBe(true); expect(headers.has("X-Customer-Id")).toBe(false); expect(headers.has("X-Roles")).toBe(false); expect(headers.has("X-User-Name")).toBe(false);
  });

  it("returns response ETags and typed safe conflict details", async () => {
    render(<ApiProvider><Probe /></ApiProvider>); await screen.findByText("SQL visible");
    screen.getByRole("button", { name: "Request" }).click(); await waitFor(() => expect(document.body.dataset.etag).toBe('"version"'));
    screen.getByRole("button", { name: "Fail" }).click(); await waitFor(() => expect(document.body.dataset.error).toBe("412:stale_version"));
  });
});
