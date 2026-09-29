import { render, screen } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { AppShell } from "@/components/AppShell";

const context = vi.hoisted(() => ({ permissions: new Set<string>() }));

vi.mock("next/navigation", () => ({ usePathname: () => "/inventory/sql-instances" }));
vi.mock("@/components/ApiContext", () => ({
  useApi: () => ({
    customerId: "customer", projectId: "project", customers: [{ id: "customer", name: "Synthetic council" }], projects: [{ id: "project", name: "Synthetic programme" }],
    setCustomerId: vi.fn(), setProjectId: vi.fn(), hasPermission: (permission: string) => context.permissions.has(permission)
  })
}));

describe("permission-aware application navigation", () => {
  beforeEach(() => { context.permissions = new Set(); });

  it("does not expose SQL routes when the server did not grant read permissions", () => {
    render(<AppShell><p>Content</p></AppShell>);
    expect(screen.queryByRole("link", { name: "SQL instances" })).not.toBeInTheDocument();
    expect(screen.queryByRole("link", { name: "SQL assessments" })).not.toBeInTheDocument();
    expect(screen.queryByRole("link", { name: "Dependencies" })).not.toBeInTheDocument();
  });

  it("exposes only granted SQL journeys and marks nested routes current", () => {
    context.permissions = new Set(["sql.inventory.read"]); render(<AppShell><p>Content</p></AppShell>);
    expect(screen.getByRole("link", { name: "SQL instances" })).toHaveAttribute("aria-current", "page");
    expect(screen.getByRole("link", { name: "SQL databases" })).toBeInTheDocument();
    expect(screen.queryByRole("link", { name: "SQL assessments" })).not.toBeInTheDocument();
  });

  it("exposes the dependency register only when the server grants dependency read", () => {
    context.permissions = new Set(["dependency.read"]); render(<AppShell><p>Content</p></AppShell>);
    expect(screen.getByRole("link", { name: "Dependencies" })).toHaveAttribute("href", "/planning/dependencies");
    expect(screen.queryByRole("link", { name: "SQL instances" })).not.toBeInTheDocument();
  });
});
