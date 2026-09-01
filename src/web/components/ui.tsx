"use client";

import { FormEvent, ReactNode, useCallback, useEffect, useState } from "react";
import { useApi } from "./ApiContext";

export function useData<T>(path: string) {
  const { api } = useApi();
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const reload = useCallback(async () => {
    setLoading(true); setError("");
    try { setData(await api<T>(path)); } catch (e) { setError(e instanceof Error ? e.message : "Unable to load data"); }
    finally { setLoading(false); }
  }, [api, path]);
  useEffect(() => { void reload(); }, [reload]);
  return { data, error, loading, reload };
}

export function PageHeader({ eyebrow, title, description, action }: { eyebrow: string; title: string; description: string; action?: ReactNode }) {
  return <div className="page-header"><div><p className="eyebrow">{eyebrow}</p><h1>{title}</h1><p>{description}</p></div>{action}</div>;
}

export function LoadState({ loading, error, children }: { loading: boolean; error: string; children: ReactNode }) {
  if (loading) return <div className="panel loading"><span className="spinner" />Loading programme data…</div>;
  if (error) return <div className="panel error"><strong>API connection unavailable</strong><p>{error}</p><small>Start the .NET API at the configured address, then refresh.</small></div>;
  return <>{children}</>;
}

export function Badge({ value }: { value: string }) {
  const tone = value.toLowerCase().replaceAll(" ", "-");
  return <span className={`badge badge-${tone}`}>{value}</span>;
}

export function Empty({ message = "No records found." }: { message?: string }) { return <div className="empty">{message}</div>; }

export function Modal({ title, children, onClose }: { title: string; children: ReactNode; onClose: () => void }) {
  return <div className="modal-backdrop" role="presentation" onMouseDown={onClose}><section className="modal" role="dialog" aria-modal="true" aria-label={title} onMouseDown={e => e.stopPropagation()}><div className="modal-header"><h2>{title}</h2><button className="icon-button" onClick={onClose} aria-label="Close">×</button></div>{children}</section></div>;
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
