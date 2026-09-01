"use client";

import { useParams } from "next/navigation";
import { useState } from "react";
import { useApi } from "@/components/ApiContext";
import { Badge, Empty, FieldError, LoadState, Modal, PageHeader, formatDate, useData } from "@/components/ui";
import { DiscoveryImport, DiscoveryImportRow, DiscoveryImportRowDetail, Paged } from "@/types/api";

const classifications = ["", "Create", "Update", "Unchanged", "Warning", "Reject"];
const sourceName = (value: string) => value === "AzureMigrateAllInventoryReport" ? "Azure Migrate All Inventory" : "Azure Migrate Server Report";

export default function DiscoveryImportPreviewPage() {
  const { id } = useParams<{ id: string }>();
  const { api } = useApi();
  const [classification, setClassification] = useState("");
  const [selected, setSelected] = useState<DiscoveryImportRowDetail | null>(null);
  const [actionError, setActionError] = useState("");
  const [acting, setActing] = useState(false);
  const batchState = useData<DiscoveryImport>(`/api/discovery/imports/${id}`);
  const rowsState = useData<Paged<DiscoveryImportRow>>(`/api/discovery/imports/${id}/rows?pageSize=200&classification=${classification}`);
  const batch = batchState.data;

  const runAction = async (action: "preview" | "commit" | "cancel") => {
    if (action === "commit" && !window.confirm("Commit this import? Approved technical changes will update Server Inventory and cannot be committed a second time.")) return;
    if (action === "cancel" && !window.confirm("Cancel this uncommitted import? It will remain visible in history.")) return;
    setActing(true); setActionError("");
    try {
      await api(`/api/discovery/imports/${id}/${action}`, { method: "POST" });
      await Promise.all([batchState.reload(), rowsState.reload()]);
    } catch (exception) { setActionError(exception instanceof Error ? exception.message : `Unable to ${action} import.`); }
    finally { setActing(false); }
  };

  const inspect = async (row: DiscoveryImportRow) => {
    setActionError("");
    try { setSelected(await api<DiscoveryImportRowDetail>(`/api/discovery/imports/${id}/rows/${row.id}`)); }
    catch (exception) { setActionError(exception instanceof Error ? exception.message : "Unable to load row details."); }
  };

  const action = batch && <div className="page-actions">
    {batch.status === "Uploaded" && <button className="button secondary" disabled={acting} onClick={() => void runAction("preview")}>Generate preview</button>}
    {["Uploaded", "PreviewReady"].includes(batch.status) && <button className="button secondary" disabled={acting} onClick={() => void runAction("cancel")}>Cancel import</button>}
    {batch.status === "PreviewReady" && batch.validRows > 0 && <button className="button primary" disabled={acting} onClick={() => void runAction("commit")}>{acting ? "Working…" : "Commit import"}</button>}
  </div>;

  return <>
    <PageHeader eyebrow="Discovery preview" title={batch?.originalFileName ?? "Import"} description={batch ? `${sourceName(batch.sourceType)} · uploaded ${formatDate(batch.uploadedAt)} by ${batch.uploadedBy}` : "Review staged discovery records before commit."} action={action} />
    <LoadState loading={batchState.loading} error={batchState.error}>
      {batch && <>
        <div className="import-meta"><Badge value={batch.status} /><span>{(batch.fileSizeBytes / 1024).toFixed(1)} KB</span><code>SHA-256 {batch.fileHash}</code></div>
        {batch.duplicateWarning && <div className="callout warning"><strong>Possible duplicate</strong><span>{batch.duplicateWarning}</span></div>}
        {batch.notes && !batch.duplicateWarning && <div className="callout warning"><strong>Import note</strong><span>{batch.notes}</span></div>}
        <section className="import-summary">
          {[["Total", batch.totalRows], ["Create", batch.createCount], ["Update", batch.updateCount], ["Unchanged", batch.unchangedCount], ["Warnings", batch.warningCount], ["Reject", batch.rejectCount]].map(([label, value]) => <article key={label}><span>{label}</span><strong>{value}</strong></article>)}
        </section>
        <FieldError value={actionError} />
        <div className="toolbar"><select value={classification} onChange={event => setClassification(event.target.value)}>{classifications.map(value => <option key={value} value={value}>{value || "All classifications"}</option>)}</select><span>{rowsState.data?.totalCount ?? 0} staged rows</span><span className="grow" /><small>Preview never changes Server Inventory</small></div>
        <LoadState loading={rowsState.loading} error={rowsState.error}>
          {rowsState.data?.items.length ? <div className="table-wrap"><table><thead><tr><th>Row</th><th>Hostname</th><th>Environment</th><th>Operating system</th><th>Current IP</th><th>Classification</th><th>Validation</th><th>Matched server</th><th /></tr></thead><tbody>
            {rowsState.data.items.map(row => <tr key={row.id}><td>{row.rowNumber}</td><td><strong>{row.hostname || "—"}</strong><small>{row.sourceRecordId}</small></td><td>{row.environment || "—"}</td><td>{row.operatingSystem || "—"}</td><td className="mono">{row.currentIp || "—"}</td><td><Badge value={row.classification} /></td><td><Badge value={row.validationStatus} /></td><td>{row.matchedServerName || "—"}</td><td><button className="text-button" onClick={() => void inspect(row)}>{row.classification === "Update" || row.classification === "Warning" ? "Review" : "Details"}</button></td></tr>)}
          </tbody></table></div> : <Empty message={batch.status === "Uploaded" ? "Generate the preview to stage and classify rows." : "No rows match this filter."} />}
        </LoadState>
      </>}
    </LoadState>
    {selected && <Modal title={`Source row ${selected.rowNumber}`} onClose={() => setSelected(null)}>
      <div className="row-detail-heading"><Badge value={selected.classification} /><Badge value={selected.validationStatus} />{selected.matchedServer && <span>Matched to <strong>{selected.matchedServer.name}</strong></span>}</div>
      <h3>Proposed technical changes</h3>
      {selected.proposedChanges.length ? <div className="change-list">{selected.proposedChanges.map(change => <article key={change.field}><strong>{change.field}</strong><span><small>Old</small>{change.oldValue || "—"}</span><span><small>New</small>{change.newValue || "—"}</span></article>)}</div> : <Empty message="No canonical technical field changes are proposed." />}
      <h3>Validation</h3>
      {selected.validationMessages.length ? <ul className="validation-list">{selected.validationMessages.map((message, index) => <li key={`${message.field}-${index}`}><Badge value={message.severity} /><span><strong>{message.field}</strong>{message.message}</span></li>)}</ul> : <p className="muted">No validation messages.</p>}
      <h3>Original source data</h3>
      <div className="source-grid">{Object.entries(selected.rawData).map(([key, value]) => <div key={key}><small>{key}</small><span>{value || "—"}</span></div>)}</div>
    </Modal>}
  </>;
}
