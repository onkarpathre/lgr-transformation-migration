import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const dependencyJourneyFiles = [
  "app/planning/dependencies/page.tsx",
  "app/planning/dependencies/new/page.tsx",
  "app/planning/dependencies/[id]/page.tsx",
  "app/planning/dependencies/assets/[assetType]/[assetId]/page.tsx"
] as const;

const assetEntryFiles = [
  "app/inventory/applications/page.tsx",
  "app/inventory/servers/page.tsx",
  "app/inventory/sql-instances/[id]/page.tsx",
  "app/inventory/sql-databases/[id]/page.tsx"
] as const;

const source = (relativePath: string) => readFileSync(resolve(process.cwd(), relativePath), "utf8");

describe("Tester-owned dependency browser journey contracts", () => {
  it("keeps all four Slice 1 routes on the authenticated central wrapper", () => {
    expect(dependencyJourneyFiles).toHaveLength(4);
    for (const file of dependencyJourneyFiles) {
      const text = source(file);
      expect(text, file).toMatch(/useApi|useData/);
      expect(text, file).not.toMatch(/\bfetch\s*\(/);
      expect(text, file).not.toMatch(/localStorage|sessionStorage|document\.cookie/);
      expect(text, file).toContain("<PageHeader");
      expect(text, file).toContain("<LoadState");
    }
  });

  it("retains bounded, permission-aware, explicit-direction and stale-write controls", () => {
    const list = source(dependencyJourneyFiles[0]);
    const create = source(dependencyJourneyFiles[1]);
    const detail = source(dependencyJourneyFiles[2]);
    const asset = source(dependencyJourneyFiles[3]);

    expect(list).toContain("pageSize=50");
    expect(list).toContain('hasPermission("dependency.manage")');
    expect(list).toContain("Depends on");
    expect(create).toContain('hasPermission("dependency.manage")');
    expect(create).toContain("never opened, called, mounted or probed");
    expect(detail).toContain('hasPermission("dependency.manage")');
    expect(detail).toContain('hasPermission("dependency.confirm")');
    expect(detail).toContain('hasPermission("dependency.audit.read")');
    expect(detail).toContain('"If-Match"');
    expect(detail).toMatch(/412|stale/i);
    expect(asset).toContain("direction=Either&pageSize=200");
    expect(asset).toContain("Depends on");
    expect(asset).toContain("Required by");
  });

  it("adds permission-aware dependency entry links to every approved asset surface", () => {
    for (const file of assetEntryFiles) {
      const text = source(file);
      expect(text, file).toContain('hasPermission("dependency.read")');
      expect(text, file).toContain("/planning/dependencies/assets/");
    }
  });
});
