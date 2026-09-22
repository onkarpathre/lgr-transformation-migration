"use client";

import { FormEvent, KeyboardEvent, ReactNode, useCallback, useEffect, useRef, useState } from "react";
import { useApi } from "./ApiContext";

export function useData<T>(path: string | null) {
  const { api } = useApi();
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const reload = useCallback(async () => {
    if (!path) { setData(null); setError(""); setLoading(false); return; }
    setLoading(true); setError("");
    try { setData(await api<T>(path)); } catch (e) { setError(e instanceof Error ? e.message : "Unable to load data"); }
    finally { setLoading(false); }
  }, [api, path]);
  useEffect(() => { void reload(); }, [reload]);
  return { data, error, loading, reload };
}

export function PageHeader({ eyebrow, title, description, action }: { eyebrow: string; title: string; description: string; action?: ReactNode }) {
  return <div className="page-header"><div><nav aria-label="Breadcrumb" className="eyebrow">{eyebrow}</nav><h1>{title}</h1><p>{description}</p></div>{action}</div>;
}

export function LoadState({ loading, error, children, onRetry }: { loading: boolean; error: string; children: ReactNode; onRetry?: () => void }) {
  if (loading) return <div className="panel loading" role="status" aria-live="polite"><span className="spinner" aria-hidden="true" />Loading programme data…</div>;
  if (error) return <div className="panel error" role="alert"><strong>Unable to load this page</strong><p>{error}</p>{onRetry && <button className="button secondary" type="button" onClick={onRetry}>Try again</button>}</div>;
  return <>{children}</>;
}

export function Badge({ value }: { value: string }) {
  const tone = value.toLowerCase().replaceAll(" ", "-");
  return <span className={`badge badge-${tone}`}>{value}</span>;
}

export function Empty({ message = "No records found.", action }: { message?: string; action?: ReactNode }) { return <div className="empty" role="status"><p>{message}</p>{action}</div>; }

export function Modal({ title, children, onClose }: { title: string; children: ReactNode; onClose: () => void }) {
  const close = useRef<HTMLButtonElement>(null);
  const dialog = useRef<HTMLElement>(null);
  useEffect(() => {
    const previous = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    close.current?.focus();
    return () => previous?.focus();
  }, []);
  const handleKeyDown = (event: KeyboardEvent<HTMLElement>) => {
    if (event.key === "Escape") { event.preventDefault(); onClose(); return; }
    if (event.key !== "Tab") return;
    const focusable = Array.from(dialog.current?.querySelectorAll<HTMLElement>("button:not([disabled]),a[href],input:not([disabled]),select:not([disabled]),textarea:not([disabled]),[tabindex]:not([tabindex='-1'])") ?? []);
    if (!focusable.length) { event.preventDefault(); return; }
    const first = focusable[0], last = focusable[focusable.length - 1];
    if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
    else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
  };
  return <div className="modal-backdrop" role="presentation" onMouseDown={onClose}><section ref={dialog} className="modal" role="dialog" aria-modal="true" aria-label={title} onKeyDown={handleKeyDown} onMouseDown={e => e.stopPropagation()}><div className="modal-header"><h2>{title}</h2><button ref={close} type="button" className="icon-button" onClick={onClose} aria-label="Close">×</button></div>{children}</section></div>;
}

export function FormActions({ onCancel, saving }: { onCancel: () => void; saving: boolean }) {
  return <div className="form-actions"><button type="button" className="button secondary" onClick={onCancel}>Cancel</button><button className="button primary" disabled={saving}>{saving ? "Saving…" : "Save"}</button></div>;
}

export function useSubmit(onSuccess: () => void) {
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState("");
  const submit = async (event: FormEvent, action: () => Promise<unknown>) => {
    event.preventDefault(); setSaving(true); setFormError("");
    try { await action(); onSuccess(); } catch (e) { setFormError(e instanceof Error ? e.message : "Unable to save"); }
    finally { setSaving(false); }
  };
  return { saving, formError, submit };
}

export function Field({ label, children, wide = false }: { label: string; children: ReactNode; wide?: boolean }) {
  return <label className={wide ? "field wide" : "field"}><span>{label}</span>{children}</label>;
}

export function formatDate(value?: string | null) {
  return value ? new Intl.DateTimeFormat("en-GB", { day: "2-digit", month: "short", year: "numeric" }).format(new Date(value)) : "—";
}

export const FieldError = ({ value }: { value: string }) => value ? <p className="form-error">{value}</p> : null;

export function StatusMessage({ message, error = false }: { message: string; error?: boolean }) {
  if (!message) return null;
  return <div className={error ? "form-error" : "form-success"} role={error ? "alert" : "status"} aria-live={error ? "assertive" : "polite"} tabIndex={-1}>{message}</div>;
}

export function Pagination({ page, pageSize, totalCount, onPage }: { page: number; pageSize: number; totalCount: number; onPage: (page: number) => void }) {
  const pages = Math.max(1, Math.ceil(totalCount / pageSize));
  if (totalCount <= pageSize && page === 1) return null;
  return <nav className="pagination" aria-label="Pagination"><button type="button" className="button secondary" disabled={page <= 1} onClick={() => onPage(page - 1)}>Previous</button><span>Page {page} of {pages}</span><button type="button" className="button secondary" disabled={page >= pages} onClick={() => onPage(page + 1)}>Next</button></nav>;
}
