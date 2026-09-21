"use client";

import { useParams } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import { ApiError, useApi } from "@/components/ApiContext";
import { Badge, Empty, LoadState, Modal, PageHeader, StatusMessage, formatDate } from "@/components/ui";
import { DiscoveryImport, DiscoveryImportRow, DiscoveryImportRowDetail, Paged, SqlDiscoveryRow, SqlDiscoveryRowDetail } from "@/types/api";

const classifications = ["", "Create", "Update", "Unchanged", "Warning", "Reject"];
const sqlSources = new Set(["SqlInstanceCsvV1", "SqlDatabaseCsvV1"]);
const sourceNames: Record<string, string> = { AzureMigrateAllInventoryReport: "Azure Migrate All Inventory", AzureMigrateServerReport: "Azure Migrate Server Report", SqlInstanceCsvV1: "SQL instance CSV v1", SqlDatabaseCsvV1: "SQL database CSV v1" };

export default function DiscoveryImportPreviewPage() {
  const { id } = useParams<{ id: string }>(); const { apiResponse, hasPermission } = useApi(); const outcome = useRef<HTMLDivElement>(null);
  const [batch, setBatch] = useState<DiscoveryImport | null>(null); const [etag, setEtag] = useState<string | null>(null); const [loading, setLoading] = useState(true); const [error, setError] = useState("");
  const [rows, setRows] = useState<Paged<DiscoveryImportRow | SqlDiscoveryRow> | null>(null); const [rowsLoading, setRowsLoading] = useState(false); const [rowsError, setRowsError] = useState(""); const [classification, setClassification] = useState(""); const [page, setPage] = useState(1);
  const [selected, setSelected] = useState<DiscoveryImportRowDetail | SqlDiscoveryRowDetail | null>(null); const [actionError, setActionError] = useState(""); const [actionMessage, setActionMessage] = useState(""); const [acting, setActing] = useState(false);
  const isSql = batch ? sqlSources.has(batch.sourceType) : false;
  const loadBatch = useCallback(async () => {
    setLoading(true); setError("");
    try {
      try { const response = await apiResponse<DiscoveryImport>(`/api/v1/discovery/imports/${id}`); setBatch(response.data); setEtag(response.etag); }
      catch (exception) { if (!(exception instanceof ApiError) || exception.status !== 404) throw exception; const response = await apiResponse<DiscoveryImport>(`/api/discovery/imports/${id}`); setBatch(response.data); setEtag(response.etag); }
    } catch (exception) { setError(exception instanceof Error ? exception.message : "Unable to load the import."); }
    finally { setLoading(false); }
  }, [apiResponse, id]);
  const loadRows = useCallback(async () => {
    if (!batch) return; setRowsLoading(true); setRowsError("");
    try { const prefix = sqlSources.has(batch.sourceType) ? "/api/v1" : "/api"; const response = await apiResponse<Paged<DiscoveryImportRow | SqlDiscoveryRow>>(`${prefix}/discovery/imports/${id}/rows?page=${page}&pageSize=50&classification=${classification}`); setRows(response.data); }
    catch (exception) { setRowsError(exception instanceof Error ? exception.message : "Unable to load reconciliation rows."); }
    finally { setRowsLoading(false); }
  }, [apiResponse, batch, id, page, classification]);
  useEffect(() => { void loadBatch(); }, [loadBatch]); useEffect(() => { void loadRows(); }, [loadRows]);
  const runAction = async (action: "preview" | "commit" | "cancel") => {
    if (!batch) return;
    if (action === "commit" && !window.confirm(`Commit ${batch.validRows} safe rows? ${batch.rejectCount} rejected rows will not apply. The batch cannot be committed twice.`)) return;
    if (action === "cancel" && !window.confirm("Cancel this uncommitted import? It will remain visible as evidence.")) return;
    setActing(true); setActionError(""); setActionMessage("");
    try {
      const prefix = isSql ? "/api/v1" : "/api"; const headers: Record<string, string> = {};
      if (isSql) { if (!etag) throw new Error("The current concurrency token is unavailable. Refresh before continuing."); headers["If-Match"] = etag; if (action === "commit") headers["Idempotency-Key"] = crypto.randomUUID(); }
      const response = await apiResponse<DiscoveryImport>(`${prefix}/discovery/imports/${id}/${action}`, { method: "POST", headers }); setBatch(response.data); setEtag(response.etag); setActionMessage(action === "commit" ? "Import committed. Safe rows and typed history were recorded atomically." : action === "cancel" ? "Import cancelled." : "Preview regenerated. Review the outcomes before commit."); setPage(1); await loadRows();
    } catch (exception) { if (exception instanceof ApiError && exception.status === 412) { setActionError("This batch changed. The latest state has been loaded; review it before trying again."); await loadBatch(); } else setActionError(exception instanceof Error ? exception.message : `Unable to ${action} the import.`); }
    finally { setActing(false); requestAnimationFrame(() => outcome.current?.focus()); }
  };
  const inspect = async (row: DiscoveryImportRow | SqlDiscoveryRow) => { setActionError(""); try { const prefix = isSql ? "/api/v1" : "/api"; setSelected((await apiResponse<DiscoveryImportRowDetail | SqlDiscoveryRowDetail>(`${prefix}/discovery/imports/${id}/rows/${row.id}`)).data); } catch (exception) { setActionError(exception instanceof ApiError && exception.status === 403 ? "Your role can view batch outcomes but not raw source-row details." : exception instanceof Error ? exception.message : "Unable to load row details."); requestAnimationFrame(() => outcome.current?.focus()); } };
  const canPrepare = !isSql || hasPermission("sql.discovery.prepare"), canCommit = !isSql || hasPermission("sql.discovery.commit"), canCancel = !isSql || hasPermission("sql.discovery.cancel");
  const renderRow = (row: DiscoveryImportRow | SqlDiscoveryRow) => {
    const sql = row as SqlDiscoveryRow; const legacy = row as DiscoveryImportRow;
    return <tr key={row.id}><td>{row.rowNumber}</td><td><strong>{sql.databaseName || sql.instanceName || legacy.hostname || "—"}</strong><small>{sql.server || legacy.sourceRecordId || ""}</small></td><td><Badge value={row.classification} /></td><td>{sql.proposedAction ?? row.classification}</td><td><Badge value={row.validationStatus} /></td><td>{sql.matchedSqlDatabase?.name || sql.matchedSqlInstance?.name || legacy.matchedServerName || "—"}</td><td><button className="text-button" onClick={() => void inspect(row)}>Review row</button></td></tr>;
  };
  const action = batch && <div className="page-actions">{batch.status === "Uploaded" && canPrepare && <button className="button secondary" disabled={acting} onClick={() => void runAction("preview")}>Generate preview</button>}{["Uploaded", "PreviewReady"].includes(batch.status) && canCancel && <button className="button secondary" disabled={acting} onClick={() => void runAction("cancel")}>Cancel import</button>}{batch.status === "PreviewReady" && batch.validRows > 0 && canCommit && <button className="button primary" disabled={acting} onClick={() => void runAction("commit")}>{acting ? "Working…" : "Commit import"}</button>}</div>;
  const rowsContent = rows?.items.length ? <div><div className="table-wrap"><table><caption>Staged reconciliation evidence</caption><thead><tr><th>Row</th><th>Source identity</th><th>Classification</th><th>Proposed action</th><th>Validation</th><th>Matched record</th><th /></tr></thead><tbody>{rows.items.map(renderRow)}</tbody></table></div><nav className="pagination" aria-label="Reconciliation pages"><button className="button secondary" disabled={page === 1} onClick={() => setPage(value => value - 1)}>Previous</button><span>Page {page} of {Math.max(1, Math.ceil(rows.totalCount / rows.pageSize))}</span><button className="button secondary" disabled={page * rows.pageSize >= rows.totalCount} onClick={() => setPage(value => value + 1)}>Next</button></nav></div> : <Empty message={batch?.status === "Uploaded" ? "Generate the preview to stage and classify rows." : "No rows match this filter."} />;
  return <><PageHeader eyebrow="Discovery / Imports / Reconciliation" title={batch?.originalFileName ?? "Import"} description={batch ? `${sourceNames[batch.sourceType] ?? batch.sourceType} · uploaded ${formatDate(batch.uploadedAt)} by ${batch.uploadedBy}` : "Review staged discovery records before commit."} action={action} /><div ref={outcome} tabIndex={-1}><StatusMessage message={actionError} error /><StatusMessage message={actionMessage} /></div>
    <LoadState loading={loading} error={error} onRetry={loadBatch}>{batch && <><div className="import-meta"><Badge value={batch.status} /><span>{(batch.fileSizeBytes / 1024).toFixed(1)} KiB</span><code>SHA-256 {batch.fileHash}</code></div>{batch.duplicateWarning && <div className="callout warning"><strong>Possible duplicate</strong><span>{batch.duplicateWarning}</span></div>}{batch.notes && !batch.duplicateWarning && <div className="callout warning"><strong>Import note</strong><span>{batch.notes}</span></div>}
      <section className="import-summary" aria-label="Reconciliation summary">{[["Total", batch.totalRows], ["Create", batch.createCount], ["Update", batch.updateCount], ["Unchanged", batch.unchangedCount], ["Warnings", batch.warningCount], ["Reject", batch.rejectCount]].map(([label, value]) => <article key={label}><span>{label}</span><strong>{value}</strong></article>)}</section>
      <div className="callout warning"><strong>Commit scope</strong><span>{batch.rejectCount} rejected rows will not apply. {batch.validRows} safe rows are eligible for one atomic commit.</span></div>
      <div className="toolbar"><label className="compact-field">Classification<select value={classification} onChange={event => { setClassification(event.target.value); setPage(1); }}>{classifications.map(value => <option key={value} value={value}>{value || "All"}</option>)}</select></label><span>{rows?.totalCount ?? 0} staged rows</span><span className="grow" /><small>Preview never changes canonical inventory</small></div>
      <LoadState loading={rowsLoading} error={rowsError} onRetry={loadRows}>{rowsContent}</LoadState>
    </>}</LoadState>
    {selected && <Modal title={`Source row ${selected.rowNumber}`} onClose={() => setSelected(null)}><div className="row-detail-heading"><Badge value={selected.classification} /><Badge value={selected.validationStatus} /></div><h3>Proposed technical changes</h3>{selected.proposedChanges.length ? <div className="change-list">{selected.proposedChanges.map(change => <article key={change.field}><strong>{change.field}</strong><span><small>Old</small>{change.oldValue || "—"}</span><span><small>New</small>{change.newValue || "—"}</span></article>)}</div> : <Empty message="No canonical technical field changes are proposed." />}<h3>Validation</h3>{selected.validationMessages.length ? <ul className="validation-list">{selected.validationMessages.map((message, index) => <li key={`${message.field}-${index}`}><Badge value={message.severity} /><span><strong>{message.field}</strong>{message.message}</span></li>)}</ul> : <p className="muted">No validation messages.</p>}<h3>Original source data</h3><div className="source-grid">{Object.entries(selected.rawData).map(([key, value]) => <div key={key}><small>{key}</small><span>{value || "—"}</span></div>)}</div></Modal>}
  </>;
}
