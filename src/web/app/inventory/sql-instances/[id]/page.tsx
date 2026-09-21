"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useState } from "react";
import { ApiError, useApi } from "@/components/ApiContext";
import { SqlInstanceForm } from "@/components/SqlInventoryForms";
import { Badge, Empty, LoadState, PageHeader, Pagination, StatusMessage, formatDate, useData } from "@/components/ui";
import { Paged, Server, SqlDatabase, SqlInstance, SqlInstanceSnapshot } from "@/types/api";

export default function SqlInstanceDetailPage() {
  const { id } = useParams<{ id: string }>(); const router = useRouter(); const { api, hasPermission } = useApi();
  const [databasePage, setDatabasePage] = useState(1); const [historyPage, setHistoryPage] = useState(1);
  const item = useData<SqlInstance>(`/api/v1/sql-instances/${id}`); const databases = useData<Paged<SqlDatabase>>(`/api/v1/sql-databases?page=${databasePage}&pageSize=50&sqlInstanceId=${id}`); const history = useData<Paged<SqlInstanceSnapshot>>(`/api/v1/sql-instances/${id}/discovery-history?page=${historyPage}&pageSize=50`); const servers = useData<Paged<Server>>("/api/servers?pageSize=200");
  const [editing, setEditing] = useState(false); const [message, setMessage] = useState(""); const [acting, setActing] = useState(false);
  const archive = async () => {
    if (!item.data || !window.confirm("Archive this SQL instance? Active databases or assessments must be resolved first.")) return;
    setActing(true); setMessage("");
    try { await api(`/api/v1/sql-instances/${id}`, { method: "DELETE", headers: { "If-Match": `"${item.data.version}"` } }); router.push("/inventory/sql-instances"); }
    catch (exception) { setMessage(exception instanceof ApiError && exception.status === 412 ? "This instance changed. The latest record has been loaded; review it before trying again." : exception instanceof Error ? exception.message : "Unable to archive this instance."); if (exception instanceof ApiError && exception.status === 412) await item.reload(); }
    finally { setActing(false); }
  };
  const actions = item.data && hasPermission("sql.inventory.update") ? <div className="page-actions"><button className="button secondary" onClick={() => setEditing(true)}>Edit</button>{hasPermission("sql.inventory.delete") && <button className="button danger" disabled={acting} onClick={() => void archive()}>Archive</button>}</div> : undefined;
  return <><PageHeader eyebrow="Inventory / SQL instances / Detail" title={item.data?.instanceName ?? "SQL instance"} description="Instance facts, linked databases and immutable discovery history." action={actions} /><StatusMessage message={message} error />
    <LoadState loading={item.loading} error={item.error} onRetry={item.reload}>{item.data && <section className="panel detail-panel"><h2>Instance details</h2><dl className="detail-list"><div><dt>Server</dt><dd>{item.data.server.name}</dd></div><div><dt>SQL version</dt><dd>{item.data.sqlVersion}</dd></div><div><dt>Edition</dt><dd>{item.data.edition}</dd></div><div><dt>Port</dt><dd>{item.data.port ?? "—"}</dd></div><div><dt>Service status</dt><dd><Badge value={item.data.serviceStatus} /></dd></div><div><dt>Discovery source</dt><dd>{item.data.discoverySource}</dd></div></dl></section>}</LoadState>
    <section className="panel section-panel" aria-labelledby="databases-heading"><h2 id="databases-heading">Linked databases</h2><LoadState loading={databases.loading} error={databases.error} onRetry={databases.reload}>{databases.data?.items.length ? <><div className="table-wrap flat"><table><caption>Databases linked to this instance</caption><thead><tr><th>Database</th><th>Size MB</th><th>Compatibility</th><th>Status</th><th /></tr></thead><tbody>{databases.data.items.map(database => <tr key={database.id}><td>{database.name}</td><td>{database.sizeMb.toLocaleString()}</td><td>{database.compatibilityLevel}</td><td><Badge value={database.status} /></td><td><Link href={`/inventory/sql-databases/${database.id}`}>View</Link></td></tr>)}</tbody></table></div><Pagination page={databases.data.page} pageSize={databases.data.pageSize} totalCount={databases.data.totalCount} onPage={setDatabasePage} /></> : <Empty message="No databases are linked to this instance." />}</LoadState></section>
    <section className="panel section-panel" aria-labelledby="history-heading"><h2 id="history-heading">Discovery history</h2><LoadState loading={history.loading} error={history.error} onRetry={history.reload}>{history.data?.items.length ? <><div className="snapshot-list">{history.data.items.map(snapshot => <article key={snapshot.id}><div><strong>{snapshot.sqlVersion} · {snapshot.edition}</strong><time dateTime={snapshot.importedAt}>{formatDate(snapshot.importedAt)}</time></div><p><span>Status: {snapshot.serviceStatus}</span><span>Port: {snapshot.port ?? "—"}</span></p><small>Source: {snapshot.sourceType} · batch {snapshot.importBatchId}</small></article>)}</div><Pagination page={history.data.page} pageSize={history.data.pageSize} totalCount={history.data.totalCount} onPage={setHistoryPage} /></> : <Empty message="No committed discovery history exists for this instance." />}</LoadState></section>
    {editing && item.data && <SqlInstanceForm existing={item.data} servers={(servers.data?.items ?? []).map(server => ({ id: server.id, name: server.hostname }))} onClose={() => setEditing(false)} onSaved={() => { setEditing(false); setMessage("Instance saved."); void item.reload(); }} />}
  </>;
}
