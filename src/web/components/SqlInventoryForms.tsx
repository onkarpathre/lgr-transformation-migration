"use client";

import { FormEvent, useRef, useState } from "react";
import { ApiError, useApi } from "./ApiContext";
import { Field, Modal, StatusMessage } from "./ui";
import { Named, SqlDatabase, SqlInstance } from "@/types/api";

const quoteEtag = (version: string) => `"${version}"`;

export function SqlInstanceForm({ existing, servers, onClose, onSaved }: { existing?: SqlInstance; servers: Named[]; onClose: () => void; onSaved: (item: SqlInstance) => void }) {
  const { api } = useApi();
  const [values, setValues] = useState({ serverId: existing?.server.id ?? "", instanceName: existing?.instanceName ?? "", sqlVersion: existing?.sqlVersion ?? "", edition: existing?.edition ?? "", port: existing?.port?.toString() ?? "", serviceStatus: existing?.serviceStatus ?? "Running", serviceAccountName: existing?.serviceAccountName ?? "" });
  const [error, setError] = useState(""); const [saving, setSaving] = useState(false);
  const errorSummary = useRef<HTMLDivElement>(null);
  const showError = (message: string) => { setError(message); requestAnimationFrame(() => errorSummary.current?.focus()); };
  const submit = async (event: FormEvent) => {
    event.preventDefault(); setError("");
    if (!values.serverId || !values.instanceName.trim() || !values.sqlVersion.trim() || !values.edition.trim()) { showError("Server, instance name, SQL version and edition are required."); return; }
    const port = values.port ? Number(values.port) : null;
    if (port !== null && (!Number.isInteger(port) || port < 1 || port > 65535)) { showError("Port must be a whole number from 1 to 65535."); return; }
    setSaving(true);
    try {
      const item = await api<SqlInstance>(existing ? `/api/v1/sql-instances/${existing.id}` : "/api/v1/sql-instances", { method: existing ? "PUT" : "POST", headers: existing ? { "If-Match": quoteEtag(existing.version) } : undefined, body: JSON.stringify({ ...values, instanceName: values.instanceName.trim(), sqlVersion: values.sqlVersion.trim(), edition: values.edition.trim(), port, serviceAccountName: values.serviceAccountName.trim() || null }) });
      onSaved(item);
    } catch (exception) { showError(exception instanceof ApiError && exception.status === 412 ? "This instance changed. Close this form and review the latest values before editing again." : exception instanceof Error ? exception.message : "Unable to save the SQL instance."); }
    finally { setSaving(false); }
  };
  return <Modal title={existing ? "Edit SQL instance" : "Add SQL instance"} onClose={onClose}><form onSubmit={submit} noValidate><div ref={errorSummary} tabIndex={-1}><StatusMessage message={error} error /></div><div className="form-grid">
    <Field label="Server" wide><select required aria-invalid={Boolean(error && !values.serverId)} value={values.serverId} onChange={event => setValues({ ...values, serverId: event.target.value })}><option value="">Select a server</option>{servers.map(server => <option value={server.id} key={server.id}>{server.name}</option>)}</select></Field>
    <Field label="Instance name"><input required aria-invalid={Boolean(error && !values.instanceName.trim())} maxLength={128} value={values.instanceName} onChange={event => setValues({ ...values, instanceName: event.target.value })} /></Field>
    <Field label="SQL version"><input required aria-invalid={Boolean(error && !values.sqlVersion.trim())} maxLength={100} value={values.sqlVersion} onChange={event => setValues({ ...values, sqlVersion: event.target.value })} /></Field>
    <Field label="Edition"><input required aria-invalid={Boolean(error && !values.edition.trim())} maxLength={100} value={values.edition} onChange={event => setValues({ ...values, edition: event.target.value })} /></Field>
    <Field label="Port"><input inputMode="numeric" aria-invalid={Boolean(error && values.port && (!Number.isInteger(Number(values.port)) || Number(values.port) < 1 || Number(values.port) > 65535))} min={1} max={65535} value={values.port} onChange={event => setValues({ ...values, port: event.target.value })} /></Field>
    <Field label="Service status"><select value={values.serviceStatus} onChange={event => setValues({ ...values, serviceStatus: event.target.value })}>{["Running", "Stopped", "Paused", "Unknown"].map(value => <option key={value}>{value}</option>)}</select></Field>
    <Field label="Service account name" wide><input maxLength={256} autoComplete="off" value={values.serviceAccountName} onChange={event => setValues({ ...values, serviceAccountName: event.target.value })} /><small>Metadata only. Do not enter passwords, keys, tokens or connection strings.</small></Field>
  </div><div className="form-actions"><button type="button" className="button secondary" onClick={onClose}>Cancel</button><button className="button primary" disabled={saving}>{saving ? "Saving…" : "Save instance"}</button></div></form></Modal>;
}

export function SqlDatabaseForm({ existing, instances, onClose, onSaved }: { existing?: SqlDatabase; instances: Named[]; onClose: () => void; onSaved: (item: SqlDatabase) => void }) {
  const { api } = useApi();
  const [values, setValues] = useState({ sqlInstanceId: existing?.sqlInstance.id ?? "", name: existing?.name ?? "", sizeMb: existing?.sizeMb.toString() ?? "0", compatibilityLevel: existing?.compatibilityLevel.toString() ?? "160", recoveryModel: existing?.recoveryModel ?? "Full", collation: existing?.collation ?? "", status: existing?.status ?? "Online" });
  const [error, setError] = useState(""); const [saving, setSaving] = useState(false);
  const errorSummary = useRef<HTMLDivElement>(null);
  const showError = (message: string) => { setError(message); requestAnimationFrame(() => errorSummary.current?.focus()); };
  const submit = async (event: FormEvent) => {
    event.preventDefault(); setError("");
    const sizeMb = Number(values.sizeMb), compatibilityLevel = Number(values.compatibilityLevel);
    if (!values.sqlInstanceId || !values.name.trim()) { showError("SQL instance and database name are required."); return; }
    if (!Number.isInteger(sizeMb) || sizeMb < 0 || !Number.isInteger(compatibilityLevel) || compatibilityLevel < 80 || compatibilityLevel > 200) { showError("Size and compatibility level must be valid whole numbers."); return; }
    setSaving(true);
    try {
      const item = await api<SqlDatabase>(existing ? `/api/v1/sql-databases/${existing.id}` : "/api/v1/sql-databases", { method: existing ? "PUT" : "POST", headers: existing ? { "If-Match": quoteEtag(existing.version) } : undefined, body: JSON.stringify({ ...values, name: values.name.trim(), sizeMb, compatibilityLevel, collation: values.collation.trim() || null }) });
      onSaved(item);
    } catch (exception) { showError(exception instanceof ApiError && exception.status === 412 ? "This database changed. Close this form and review the latest values before editing again." : exception instanceof Error ? exception.message : "Unable to save the SQL database."); }
    finally { setSaving(false); }
  };
  return <Modal title={existing ? "Edit SQL database" : "Add SQL database"} onClose={onClose}><form onSubmit={submit} noValidate><div ref={errorSummary} tabIndex={-1}><StatusMessage message={error} error /></div><div className="form-grid">
    <Field label="SQL instance" wide><select required aria-invalid={Boolean(error && !values.sqlInstanceId)} value={values.sqlInstanceId} onChange={event => setValues({ ...values, sqlInstanceId: event.target.value })}><option value="">Select an instance</option>{instances.map(instance => <option value={instance.id} key={instance.id}>{instance.name}</option>)}</select></Field>
    <Field label="Database name"><input required aria-invalid={Boolean(error && !values.name.trim())} maxLength={128} value={values.name} onChange={event => setValues({ ...values, name: event.target.value })} /></Field>
    <Field label="Size (MB)"><input required inputMode="numeric" aria-invalid={Boolean(error && (!Number.isInteger(Number(values.sizeMb)) || Number(values.sizeMb) < 0))} min={0} value={values.sizeMb} onChange={event => setValues({ ...values, sizeMb: event.target.value })} /></Field>
    <Field label="Compatibility level"><input required inputMode="numeric" aria-invalid={Boolean(error && (!Number.isInteger(Number(values.compatibilityLevel)) || Number(values.compatibilityLevel) < 80 || Number(values.compatibilityLevel) > 200))} min={80} max={200} value={values.compatibilityLevel} onChange={event => setValues({ ...values, compatibilityLevel: event.target.value })} /></Field>
    <Field label="Recovery model"><select value={values.recoveryModel} onChange={event => setValues({ ...values, recoveryModel: event.target.value })}>{["Full", "Simple", "BulkLogged"].map(value => <option key={value}>{value}</option>)}</select></Field>
    <Field label="Status"><select value={values.status} onChange={event => setValues({ ...values, status: event.target.value })}>{["Online", "Offline", "Restoring", "Recovering", "Suspect", "Emergency", "Unknown"].map(value => <option key={value}>{value}</option>)}</select></Field>
    <Field label="Collation" wide><input maxLength={128} value={values.collation} onChange={event => setValues({ ...values, collation: event.target.value })} /></Field>
  </div><div className="form-actions"><button type="button" className="button secondary" onClick={onClose}>Cancel</button><button className="button primary" disabled={saving}>{saving ? "Saving…" : "Save database"}</button></div></form></Modal>;
}
