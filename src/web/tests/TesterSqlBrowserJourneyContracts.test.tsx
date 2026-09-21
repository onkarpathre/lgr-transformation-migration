import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ApiProvider, useApi } from "@/components/ApiContext";

const journeyFiles = [
  "app/inventory/sql-instances/page.tsx",
  "app/inventory/sql-instances/[id]/page.tsx",
  "app/inventory/sql-databases/page.tsx",
  "app/inventory/sql-databases/[id]/page.tsx",
  "app/discovery/imports/page.tsx",
  "app/discovery/imports/new/page.tsx",
  "app/discovery/imports/[id]/page.tsx",
  "app/assessment/sql/page.tsx",
  "app/assessment/sql/[id]/page.tsx"
] as const;

const source = (relativePath: string) => readFileSync(resolve(process.cwd(), relativePath), "utf8");
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { "Content-Type": "application/json" }
});

function HeaderProbe() {
  const { api } = useApi();
  return <button onClick={() => void api("/api/v1/probe", {
    headers: { "X-Lgr-Test-Principal": "caller-controlled" }
  })}>Probe headers</button>;
}

describe("Tester-owned SQL browser journey contracts", () => {
  beforeEach(() => {
    vi.stubGlobal("fetch", vi.fn((input: string | URL) => {
      const url = input.toString();
      if (url.endsWith("/api/customers")) return Promise.resolve(json([{ id: "c", name: "Council" }]));
      if (url.endsWith("/api/projects")) return Promise.resolve(json([{ id: "p", name: "Programme" }]));
      if (url.endsWith("/api/v1/session/capabilities")) return Promise.resolve(json({ permissions: [] }));
      return Promise.resolve(json({ ok: true }));
    }));
  });

  it("keeps all nine approved journeys on the authenticated central wrapper", () => {
    expect(journeyFiles).toHaveLength(9);
    for (const file of journeyFiles) {
      const text = source(file);
      expect(text, file).toMatch(/useApi|useData/);
      expect(text, file).not.toMatch(/\bfetch\s*\(/);
      expect(text, file).not.toMatch(/localStorage|sessionStorage|document\.cookie/);
      expect(text, file).toContain("<PageHeader");
      expect(text, file).toContain("<LoadState");
    }
  });

  it("retains route-specific permission, bounded paging, stale-write and record-only controls", () => {
    const instanceList = source(journeyFiles[0]);
    const databaseList = source(journeyFiles[2]);
    const importList = source(journeyFiles[4]);
    const importDetail = source(journeyFiles[6]);
    const assessmentList = source(journeyFiles[7]);
    const assessmentDetail = source(journeyFiles[8]);

    expect(instanceList).toContain('hasPermission("sql.inventory.create")');
    expect(databaseList).toContain('hasPermission("sql.inventory.create")');
    expect(instanceList).toContain("pageSize=50");
    expect(databaseList).toContain("pageSize=50");
    expect(importList).toContain('hasPermission("sql.discovery.read")');
    expect(importDetail).toContain('"If-Match"');
    expect(importDetail).toMatch(/412|stale/i);
    expect(assessmentList).toContain('hasPermission("sql.assessment.manage")');
    expect(assessmentDetail).toContain('hasPermission("sql.assessment.manage")');
    expect(assessmentDetail).toContain('hasPermission("sql.assessment.plan")');
    expect(assessmentDetail).toContain('"If-Match"');
    expect(assessmentDetail).toContain("cannot execute migration");
  });

  it("suppresses caller-controlled development identity headers outside development", async () => {
    render(<ApiProvider><HeaderProbe /></ApiProvider>);
    await waitFor(() => expect(vi.mocked(fetch).mock.calls.some(call => call[0].toString().endsWith("/api/v1/session/capabilities"))).toBe(true));
    fireEvent.click(screen.getByRole("button", { name: "Probe headers" }));
    await waitFor(() => expect(vi.mocked(fetch).mock.calls.some(call => call[0].toString().endsWith("/api/v1/probe"))).toBe(true));

    const probe = vi.mocked(fetch).mock.calls.find(call => call[0].toString().endsWith("/api/v1/probe"));
    const init = probe?.[1] as RequestInit;
    const headers = new Headers(init.headers);
    expect(init.cache).toBe("no-store");
    expect(headers.get("X-Project-Id")).toBeTruthy();
    expect(headers.has("X-Lgr-Test-Principal")).toBe(false);
    expect(headers.has("X-Customer-Id")).toBe(false);
    expect(headers.has("X-Roles")).toBe(false);
    expect(headers.has("X-Permissions")).toBe(false);
    expect(headers.has("X-User-Name")).toBe(false);
  });
});
