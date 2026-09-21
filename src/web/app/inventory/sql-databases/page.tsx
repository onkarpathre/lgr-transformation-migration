"use client";

import Link from "next/link";
import { useState } from "react";
import { useApi } from "@/components/ApiContext";
import { SqlDatabaseForm } from "@/components/SqlInventoryForms";
import { Badge, Empty, LoadState, PageHeader, Pagination, formatDate, useData } from "@/components/ui";
import { Paged, SqlDatabase, SqlInstance } from "@/types/api";

export default function SqlDatabasesPage() {
  const { hasPermission } = useApi(); const canCreate = hasPermission("sql.inventory.create");
  const [search, setSearch] = useState(""); const [status, setStatus] = useState(""); const [page, setPage] = useState(1); const [adding, setAdding] = useState(false);
  const state = useData<Paged<SqlDatabase>>(`/api/v1/sql-databases?page=${page}&pageSize=50&search=${encodeURIComponent(search)}&status=${encodeURIComponent(status)}`); const instances = useData<Paged<SqlInstance>>("/api/v1/sql-instances?pageSize=200");
  const items = state.data?.items ?? [];
  return <><PageHeader eyebrow="Inventory / SQL databases" title="SQL databases" description="Governed SQL database inventory linked to an in-project SQL instance." action={canCreate ? <button className="button primary" onClick={() => setAdding(true)}>Add SQL database</button> : undefined} />
    <div className="toolbar"><label className="search"><span aria-hidden="true">⌕</span><input aria-label="Search SQL databases" value={search} onChange={event => { setSearch(event.target.value); setPage(1); }} placeholder="Search SQL inventory" /></label><label className="compact-field">Status<select value={status} onChange={event => { setStatus(event.target.value); setPage(1); }}><option value="">All</option>{["Online", "Offline", "Restoring", "Recovering", "Suspect", "Emergency", "Unknown"].map(value => <option key={value}>{value}</option>)}</select></label><span>{state.data?.totalCount ?? 0} databases</span></div>
    <LoadState loading={state.loading} error={state.error} onRetry={state.reload}>{items.length ? <><div className="table-wrap"><table><caption>SQL databases in the active project</caption><thead><tr><th>Database</th><th>Instance</th><th>Size MB</th><th>Compatibility</th><th>Recovery</th><th>Status</th><th>Last imported</th><th /></tr></thead><tbody>{items.map(item => <tr key={item.id}><td><strong>{item.name}</strong><small>{item.collation ?? "Default collation"}</small></td><td>{item.sqlInstance.name}</td><td>{item.sizeMb.toLocaleString()}</td><td>{item.compatibilityLevel}</td><td>{item.recoveryModel}</td><td><Badge value={item.status} /></td><td>{formatDate(item.lastImportedAt)}</td><td><Link className="text-button" href={`/inventory/sql-databases/${item.id}`}>View details</Link></td></tr>)}</tbody></table></div><Pagination page={state.data?.page ?? page} pageSize={state.data?.pageSize ?? 50} totalCount={state.data?.totalCount ?? 0} onPage={setPage} /></> : <Empty message="No SQL databases match this view." action={canCreate ? <button className="button secondary" onClick={() => setAdding(true)}>Add the first database</button> : undefined} />}</LoadState>
    {adding && <SqlDatabaseForm instances={(instances.data?.items ?? []).map(item => ({ id: item.id, name: `${item.server.name} / ${item.instanceName}` }))} onClose={() => setAdding(false)} onSaved={() => { setAdding(false); void state.reload(); }} />}
  </>;
}
