import { fireEvent, render, screen } from "@testing-library/react";
import axe from "axe-core";
import { describe, expect, it, vi } from "vitest";
import { Empty, LoadState, Modal, PageHeader, Pagination, StatusMessage } from "@/components/ui";

describe("accessible shared journey states", () => {
  it("announces loading and safe retryable errors", () => {
    const retry = vi.fn(); const { rerender } = render(<LoadState loading error=""><span>content</span></LoadState>);
    expect(screen.getByRole("status").textContent).toContain("Loading programme data");
    rerender(<LoadState loading={false} error="The request is not available." onRetry={retry}><span>content</span></LoadState>);
    expect(screen.getByRole("alert").textContent).toContain("The request is not available."); fireEvent.click(screen.getByRole("button", { name: "Try again" })); expect(retry).toHaveBeenCalledOnce();
  });

  it("exposes empty and mutation outcomes through live regions", () => {
    render(<><Empty message="No SQL records." /><StatusMessage message="Assessment saved." /><StatusMessage message="Conflict detected." error /></>);
    expect(screen.getAllByRole("status").map(node => node.textContent)).toContain("Assessment saved."); expect(screen.getByRole("alert").textContent).toBe("Conflict detected.");
  });

  it("provides a labelled breadcrumb and level-one heading", () => {
    render(<PageHeader eyebrow="Inventory / SQL" title="SQL instances" description="Inventory" />);
    expect(screen.getByRole("navigation", { name: "Breadcrumb" })).toHaveTextContent("Inventory / SQL"); expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("SQL instances");
  });

  it("focuses and closes a keyboard-operable modal", () => {
    const close = vi.fn(); render(<Modal title="Edit assessment" onClose={close}><button>Save</button></Modal>);
    expect(screen.getByRole("button", { name: "Close" })).toHaveFocus(); fireEvent.keyDown(screen.getByRole("dialog"), { key: "Escape" }); expect(close).toHaveBeenCalledOnce();
  });

  it("contains keyboard focus inside a modal", () => {
    render(<Modal title="Edit assessment" onClose={vi.fn()}><button>Save</button></Modal>);
    const close = screen.getByRole("button", { name: "Close" }); const save = screen.getByRole("button", { name: "Save" });
    close.focus(); fireEvent.keyDown(screen.getByRole("dialog"), { key: "Tab", shiftKey: true }); expect(save).toHaveFocus();
    fireEvent.keyDown(screen.getByRole("dialog"), { key: "Tab" }); expect(close).toHaveFocus();
  });

  it("offers bounded keyboard-operable pagination", () => {
    const change = vi.fn(); render(<Pagination page={2} pageSize={50} totalCount={125} onPage={change} />);
    expect(screen.getByRole("navigation", { name: "Pagination" })).toHaveTextContent("Page 2 of 3");
    fireEvent.click(screen.getByRole("button", { name: "Previous" })); fireEvent.click(screen.getByRole("button", { name: "Next" }));
    expect(change).toHaveBeenNthCalledWith(1, 1); expect(change).toHaveBeenNthCalledWith(2, 3);
  });

  it("has no automated axe violations in representative shared states", async () => {
    const { container } = render(<main><PageHeader eyebrow="Assessment / SQL" title="SQL assessments" description="Human planning evidence" /><Empty message="No assessments." action={<button>Create assessment</button>} /></main>);
    expect((await axe.run(container)).violations).toEqual([]);
  });
});
