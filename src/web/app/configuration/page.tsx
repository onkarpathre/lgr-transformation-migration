"use client";

import { useMemo, useState } from "react";
import { useApi } from "@/components/ApiContext";
import { Badge, Field, FieldError, FormActions, LoadState, Modal, PageHeader, useData, useSubmit } from "@/components/ui";
import { Lookup } from "@/types/api";

const blank = { group: "Environment", value: "", displayName: "", sortOrder: 100, isActive: true };

export default function ConfigurationPage() {
  const { api } = useApi(); const lookups = useData<Lookup[]>("/api/configuration"); const [group, setGroup] = useState(""); const [open, setOpen] = useState(false); const [form, setForm] = useState(blank); const { saving, formError, submit } = useSubmit(() => { setOpen(false); setForm(blank); void lookups.reload(); });
  const groups = useMemo(() => Array.from(new Set(lookups.data?.map(x => x.group) ?? [])), [lookups.data]); const rows = lookups.data?.filter(x => !group || x.group === group) ?? [];
  return <><PageHeader eyebrow="Administration" title="Configuration" description="Global and customer-specific lookup values used by programme records." action={<button className="button primary" onClick={() => setOpen(true)}>Add customer value</button>} />
    <LoadState loading={lookups.loading} error={lookups.error}><div className="toolbar"><select value={group} onChange={e => setGroup(e.target.value)}><option value="">All lookup groups</option>{groups.map(x => <option key={x}>{x}</option>)}</select><span>{rows.length} values</span></div><div className="table-wrap"><table><thead><tr><th>Group</th><th>Value</th><th>Display name</th><th>Order</th><th>Scope</th><th>Status</th></tr></thead><tbody>{rows.map(x => <tr key={x.id}><td><strong>{x.group}</strong></td><td>{x.value}</td><td>{x.displayName}</td><td>{x.sortOrder}</td><td>{x.customerId ? "Demo Council" : "Global default"}</td><td><Badge value={x.isActive ? "Active" : "Inactive"} /></td></tr>)}</tbody></table></div></LoadState>
    {open && <Modal title="Add customer lookup value" onClose={() => setOpen(false)}><form onSubmit={e => submit(e, () => api("/api/configuration", { method: "POST", body: JSON.stringify(form) }))}><div className="form-grid"><Field label="Lookup group"><select value={form.group} onChange={e => setForm({ ...form, group: e.target.value })}>{groups.map(x => <option key={x}>{x}</option>)}</select></Field><Field label="Value"><input required value={form.value} onChange={e => setForm({ ...form, value: e.target.value })} /></Field><Field label="Display name"><input required value={form.displayName} onChange={e => setForm({ ...form, displayName: e.target.value })} /></Field><Field label="Sort order"><input type="number" value={form.sortOrder} onChange={e => setForm({ ...form, sortOrder: Number(e.target.value) })} /></Field></div><FieldError value={formError} /><FormActions saving={saving} onCancel={() => setOpen(false)} /></form></Modal>}
  </>;
}
