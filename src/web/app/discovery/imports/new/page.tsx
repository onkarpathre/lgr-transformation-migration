"use client";

import Link from "next/link";
import { FormEvent, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { ApiError, useApi } from "@/components/ApiContext";
import { Field, LoadState, PageHeader, StatusMessage } from "@/components/ui";
import { DiscoveryImport } from "@/types/api";

const SQL_SOURCES = new Set(["SqlInstanceCsvV1", "SqlDatabaseCsvV1"]);

export default function NewDiscoveryImportPage() {
  const router = useRouter(); const summary = useRef<HTMLDivElement>(null);
  const { api, apiResponse, customerId, projectId, customers, projects, hasPermission, capabilitiesLoading } = useApi();
  const [sourceType, setSourceType] = useState("SqlInstanceCsvV1"); const [file, setFile] = useState<File | null>(null); const [saving, setSaving] = useState(false); const [error, setError] = useState("");
  const canPrepareSql = hasPermission("sql.discovery.prepare");
  useEffect(() => { if (!capabilitiesLoading && !canPrepareSql && SQL_SOURCES.has(sourceType)) setSourceType("AzureMigrateServerReport"); }, [canPrepareSql, capabilitiesLoading, sourceType]);
  const customer = customers.find(x => x.id === customerId)?.name ?? customerId; const project = projects.find(x => x.id === projectId)?.name ?? projectId;
  const upload = async (event: FormEvent) => {
    event.preventDefault(); setError("");
    if (!file) { setError("Select a CSV file to upload."); summary.current?.focus(); return; }
    if (!file.name.toLowerCase().endsWith(".csv")) { setError("Only a .csv file is accepted."); summary.current?.focus(); return; }
    if (file.size === 0 || file.size > 25 * 1024 * 1024) { setError("The CSV must contain data and be no larger than 25 MiB."); summary.current?.focus(); return; }
    setSaving(true);
    try {
      const body = new FormData(); body.append("SourceType", sourceType); body.append("File", file);
      if (SQL_SOURCES.has(sourceType)) {
        const uploaded = await apiResponse<DiscoveryImport>("/api/v1/discovery/imports/upload", { method: "POST", body });
        if (!uploaded.etag) throw new Error("The upload did not return a concurrency token.");
        await api(`/api/v1/discovery/imports/${uploaded.data.id}/preview`, { method: "POST", headers: { "If-Match": uploaded.etag } });
        router.push(`/discovery/imports/${uploaded.data.id}`);
      } else {
        const batch = await api<DiscoveryImport>("/api/discovery/imports/upload", { method: "POST", body });
        await api(`/api/discovery/imports/${batch.id}/preview`, { method: "POST" }); router.push(`/discovery/imports/${batch.id}`);
      }
    } catch (exception) { setError(exception instanceof ApiError && exception.status === 412 ? "The staged import changed before preview. Open the batch and review the latest state." : exception instanceof Error ? exception.message : "Unable to upload the discovery file."); requestAnimationFrame(() => summary.current?.focus()); }
    finally { setSaving(false); }
  };
  if (capabilitiesLoading) return <><PageHeader eyebrow="Discovery / Imports / New" title="New import" description="Checking project permissions." /><LoadState loading error=""><span /></LoadState></>;
  return <><PageHeader eyebrow="Discovery / Imports / New" title="New import" description="The CSV is validated and staged. Canonical inventory changes only after an explicit commit." />
    <form className="panel import-form" onSubmit={upload} noValidate><div ref={summary} tabIndex={-1}><StatusMessage message={error} error /></div><div className="context-summary"><span><small>Customer</small><strong>{customer}</strong></span><span><small>Project</small><strong>{project}</strong></span></div><div className="form-grid">
      <Field label="Source type" wide><select value={sourceType} onChange={event => setSourceType(event.target.value)}>{canPrepareSql && <><option value="SqlInstanceCsvV1">SQL instance CSV v1</option><option value="SqlDatabaseCsvV1">SQL database CSV v1</option></>}<option value="AzureMigrateServerReport">Azure Migrate Server Report</option><option value="AzureMigrateAllInventoryReport">Azure Migrate All Inventory Report</option></select><small>Select the exact approved contract. SQL source types appear only when the server grants prepare permission; all content is verified server-side.</small></Field>
      <Field label="Discovery file" wide><input type="file" required accept=".csv,text/csv" onChange={event => setFile(event.target.files?.[0] ?? null)} /><small>UTF-8 CSV only, maximum 25 MiB, 50,000 data rows and 64 columns.</small></Field>
    </div><div className="import-notice"><strong>Preview first</strong><span>Rejected rows never apply. A later commit applies the complete safe reconciliation atomically.</span></div><div className="form-actions"><Link className="button secondary" href="/discovery/imports">Cancel</Link><button className="button primary" disabled={saving}>{saving ? "Uploading and previewing…" : "Upload and preview"}</button></div></form>
  </>;
}
