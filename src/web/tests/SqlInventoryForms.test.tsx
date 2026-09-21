import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { SqlDatabaseForm, SqlInstanceForm } from "@/components/SqlInventoryForms";

vi.mock("@/components/ApiContext", () => ({ useApi: () => ({ api: vi.fn() }) }));

describe("SQL inventory forms", () => {
  it("links required instance validation to an announced summary", () => {
    render(<SqlInstanceForm servers={[]} onClose={vi.fn()} onSaved={vi.fn()} />); fireEvent.click(screen.getByRole("button", { name: "Save instance" })); expect(screen.getByRole("alert").textContent).toContain("required");
  });

  it("rejects an unsafe out-of-range port before any API mutation", () => {
    render(<SqlInstanceForm servers={[{ id: "server", name: "Synthetic server" }]} onClose={vi.fn()} onSaved={vi.fn()} />); fireEvent.change(screen.getByLabelText("Server"), { target: { value: "server" } }); fireEvent.change(screen.getByLabelText("Instance name"), { target: { value: "SQL01" } }); fireEvent.change(screen.getByLabelText("SQL version"), { target: { value: "2022" } }); fireEvent.change(screen.getByLabelText("Edition"), { target: { value: "Standard" } }); fireEvent.change(screen.getByLabelText("Port"), { target: { value: "70000" } }); fireEvent.click(screen.getByRole("button", { name: "Save instance" })); expect(screen.getByRole("alert").textContent).toContain("1 to 65535");
  });

  it("validates database ownership and numeric boundaries", () => {
    render(<SqlDatabaseForm instances={[]} onClose={vi.fn()} onSaved={vi.fn()} />); fireEvent.click(screen.getByRole("button", { name: "Save database" })); expect(screen.getByRole("alert").textContent).toContain("required");
  });
});
