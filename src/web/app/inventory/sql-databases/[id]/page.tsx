"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useState } from "react";
import { ApiError, useApi } from "@/components/ApiContext";
import { SqlDatabaseForm } from "@/components/SqlInventoryForms";
import { Badge, Empty, LoadState, PageHeader, Pagination, StatusMessage, formatDate, useData } from "@/components/ui";
import { Paged, SqlDatabase, SqlDatabaseSnapshot, SqlInstance } from "@/types/api";

export default function SqlDatabaseDetailPage() {
  const { id } = useParams<{ id: string }>(); const router = useRouter(); const { api, hasPermission } = useApi();
  const [historyPage, setHistoryPage] = useState(1);
  const item = useData<SqlDatabase>(`/api/v1/sql-databases/${id}`); const history = useData<Paged<SqlDatabaseSnapshot>>(`/api/v1/sql-databases/${id}/discovery-history?page=${historyPage}&pageSize=50`); const instances = useData<Paged<SqlInstance>>("/api/v1/sql-instances?pageSize=200");
  const [editing, setEditing] = useState(false); const [message, setMessage] = useState(""); const [acting, setActing] = useState(false);
  const archive = async () => {
    if (!item.data || !window.confirm("Archive this SQL database? Any active assessment must be resolved first.")) return;
    setActing(true); setMessage("");
    try { await api(`/api/v1/sql-databases/${id}`, { method: "DELETE", headers: { "If-Match": `"${item.data.version}"` } }); router.push("/inventory/sql-databases"); }
    catch (exception) { setMessage(exception instanceof ApiError && exception.status === 412 ? "This database changed. The latest record has been loaded; review it before trying again." : exception instanceof Error ? exception.message : "Unable to archive this database."); if (exception instanceof ApiError && exception.status === 412) await item.reload(); }
    finally { setActing(false); }
  };
  const actions = item.data && (hasPermission("dependency.read") || hasPermission("sql.inventory.update")) ? <div className="page-actions">{hasPermission("dependency.read") && <Link className="button secondary" href={`/planning/dependencies/assets/SqlDatabase/${id}`}>Dependencies</Link>}{hasPermission("sql.inventory.update") && <button className="button secondary" onClick={() => setEditing(true)}>Edit</button>}{hasPermission("sql.inventory.delete") && <button className="button danger" disabled={acting} onClick={() => void archive()}>Archive</button>}</div> : undefined;
  return <><PageHeader eyebrow="Inventory / SQL databases / Detail" title={item.data?.name ?? "SQL database"} description="Database facts, parent instance and immutable discovery history." action={actions} /><StatusMessage message={message} error />
    <LoadState loading={item.loading} error={item.error} onRetry={item.reload}>{item.data && <section className="panel detail-panel"><h2>Database details</h2><dl className="detail-list"><div><dt>SQL instance</dt><dd><Link href={`/inventory/sql-instances/${item.data.sqlInstance.id}`}>{item.data.sqlInstance.name}</Link></dd></div><div><dt>Size</dt><dd>{item.data.sizeMb.toLocaleString()} MB</dd></div><div><dt>Compatibility level</dt><dd>{item.data.compatibilityLevel}</dd></div><div><dt>Recovery model</dt><dd>{item.data.recoveryModel}</dd></div><div><dt>Collation</dt><dd>{item.data.collation ?? "Default"}</dd></div><div><dt>Status</dt><dd><Badge value={item.data.status} /></dd></div></dl></section>}</LoadState>
    <section className="panel section-panel" aria-labelledby="history-heading"><h2 id="history-heading">Discovery history</h2><LoadState loading={history.loading} error={history.error} onRetry={history.reload}>{history.data?.items.length ? <><div className="snapshot-list">{history.data.items.map(snapshot => <article key={snapshot.id}><div><strong>{snapshot.name}</strong><time dateTime={snapshot.importedAt}>{formatDate(snapshot.importedAt)}</time></div><p><span>{snapshot.sizeMb.toLocaleString()} MB</span><span>Compatibility {snapshot.compatibilityLevel}</span><span>{snapshot.recoveryModel}</span></p><small>Source: {snapshot.sourceType} · batch {snapshot.importBatchId}</small></article>)}</div><Pagination page={history.data.page} pageSize={history.data.pageSize} totalCount={history.data.totalCount} onPage={setHistoryPage} /></> : <Empty message="No committed discovery history exists for this database." />}</LoadState></section>
    {editing && item.data && <SqlDatabaseForm existing={item.data} instances={(instances.data?.items ?? []).map(instance => ({ id: instance.id, name: `${instance.server.name} / ${instance.instanceName}` }))} onClose={() => setEditing(false)} onSaved={() => { setEditing(false); setMessage("Database saved."); void item.reload(); }} />}
  </>;
}
