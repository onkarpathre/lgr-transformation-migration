"use client";

import { useState } from "react";
import { useApi } from "@/components/ApiContext";
import { Badge, Field, FieldError, FormActions, LoadState, Modal, PageHeader, formatDate, useData, useSubmit } from "@/components/ui";
import { Customer } from "@/types/api";

export default function CustomersPage() {
  const { api } = useApi();
  const { data, loading, error, reload } = useData<Customer[]>("/api/customers");
  const [editing, setEditing] = useState<Customer | null>(null);
  const { saving, formError, submit } = useSubmit(() => { setEditing(null); void reload(); });
  return <>
    <PageHeader eyebrow="Administration" title="Customers" description="Customer tenancy and programme ownership." />
    <LoadState loading={loading} error={error}><div className="card-grid">{data?.map(customer => <article className="customer-card" key={customer.id}><div className="customer-monogram">DC</div><div className="grow"><div className="title-line"><h2>{customer.name}</h2><Badge value={customer.status} /></div><p>Customer code <strong>{customer.code}</strong></p><small>Updated {formatDate(customer.updatedAt)}</small></div><button className="button secondary" onClick={() => setEditing(customer)}>Edit customer</button></article>)}</div></LoadState>
    {editing && <Modal title="Edit customer" onClose={() => setEditing(null)}><form onSubmit={e => submit(e, () => api(`/api/customers/${editing.id}`, { method: "PUT", body: JSON.stringify(editing) }))}><div className="form-grid"><Field label="Name" wide><input required value={editing.name} onChange={e => setEditing({ ...editing, name: e.target.value })} /></Field><Field label="Code"><input required value={editing.code} onChange={e => setEditing({ ...editing, code: e.target.value })} /></Field><Field label="Status"><select value={editing.status} onChange={e => setEditing({ ...editing, status: e.target.value })}><option>Active</option><option>Inactive</option></select></Field></div><FieldError value={formError} /><FormActions saving={saving} onCancel={() => setEditing(null)} /></form></Modal>}
  </>;
}
