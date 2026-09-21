"use client";

import Link from "next/link";
import { useState } from "react";
import { useApi } from "@/components/ApiContext";
import { SqlInstanceForm } from "@/components/SqlInventoryForms";
import { Badge, Empty, LoadState, PageHeader, Pagination, formatDate, useData } from "@/components/ui";
import { Paged, Server, SqlInstance } from "@/types/api";

export default function SqlInstancesPage() {
  const { hasPermission } = useApi(); const canCreate = hasPermission("sql.inventory.create");
  const [search, setSearch] = useState(""); const [status, setStatus] = useState(""); const [page, setPage] = useState(1); const [adding, setAdding] = useState(false);
  const state = useData<Paged<SqlInstance>>(`/api/v1/sql-instances?page=${page}&pageSize=50&search=${encodeURIComponent(search)}&serviceStatus=${encodeURIComponent(status)}`);
  const servers = useData<Paged<Server>>("/api/servers?pageSize=200");
  const items = state.data?.items ?? [];
  return <><PageHeader eyebrow="Inventory / SQL instances" title="SQL instances" description="Governed SQL Server instance inventory for the active project." action={canCreate ? <button className="button primary" onClick={() => setAdding(true)}>Add SQL instance</button> : undefined} />
    <div className="toolbar"><label className="search"><span aria-hidden="true">⌕</span><input aria-label="Search SQL instances" value={search} onChange={event => { setSearch(event.target.value); setPage(1); }} placeholder="Search SQL inventory" /></label><label className="compact-field">Service status<select value={status} onChange={event => { setStatus(event.target.value); setPage(1); }}><option value="">All</option>{["Running", "Stopped", "Paused", "Unknown"].map(value => <option key={value}>{value}</option>)}</select></label><span>{state.data?.totalCount ?? 0} instances</span></div>
    <LoadState loading={state.loading} error={state.error} onRetry={state.reload}>{items.length ? <><div className="table-wrap"><table><caption>SQL instances in the active project</caption><thead><tr><th>Instance</th><th>Server</th><th>Version</th><th>Edition</th><th>Port</th><th>Status</th><th>Last imported</th><th /></tr></thead><tbody>{items.map(item => <tr key={item.id}><td><strong>{item.instanceName}</strong><small>{item.discoverySource}</small></td><td>{item.server.name}</td><td>{item.sqlVersion}</td><td>{item.edition}</td><td>{item.port ?? "—"}</td><td><Badge value={item.serviceStatus} /></td><td>{formatDate(item.lastImportedAt)}</td><td><Link className="text-button" href={`/inventory/sql-instances/${item.id}`}>View details</Link></td></tr>)}</tbody></table></div><Pagination page={state.data?.page ?? page} pageSize={state.data?.pageSize ?? 50} totalCount={state.data?.totalCount ?? 0} onPage={setPage} /></> : <Empty message="No SQL instances match this view." action={canCreate ? <button className="button secondary" onClick={() => setAdding(true)}>Add the first instance</button> : undefined} />}</LoadState>
    {adding && <SqlInstanceForm servers={(servers.data?.items ?? []).map(item => ({ id: item.id, name: item.hostname }))} onClose={() => setAdding(false)} onSaved={() => { setAdding(false); void state.reload(); }} />}
  </>;
}
