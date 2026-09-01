"use client";

import Link from "next/link";
import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { useApi } from "@/components/ApiContext";
import { Field, FieldError, PageHeader } from "@/components/ui";
import { DiscoveryImport } from "@/types/api";

export default function NewDiscoveryImportPage() {
  const router = useRouter();
  const { api, customerId, projectId, customers, projects } = useApi();
  const [sourceType, setSourceType] = useState("AzureMigrateServerReport");
  const [file, setFile] = useState<File | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const customer = customers.find(x => x.id === customerId)?.name ?? customerId;
  const project = projects.find(x => x.id === projectId)?.name ?? projectId;

  const upload = async (event: FormEvent) => {
    event.preventDefault();
    if (!file) { setError("Select a CSV report to upload."); return; }
    setSaving(true); setError("");
    try {
      const body = new FormData();
      body.append("SourceType", sourceType);
      body.append("File", file);
      const batch = await api<DiscoveryImport>("/api/discovery/imports/upload", { method: "POST", body });
      await api<DiscoveryImport>(`/api/discovery/imports/${batch.id}/preview`, { method: "POST" });
      router.push(`/discovery/imports/${batch.id}`);
    } catch (exception) {
      setError(exception instanceof Error ? exception.message : "Unable to upload the discovery report.");
    } finally { setSaving(false); }
  };

  return <>
    <PageHeader eyebrow="Discovery import" title="New import" description="The report is validated and staged for preview. Server inventory is not changed until you explicitly commit." />
    <form className="panel import-form" onSubmit={upload}>
      <div className="context-summary"><span><small>Customer</small><strong>{customer}</strong></span><span><small>Project</small><strong>{project}</strong></span></div>
      <div className="form-grid">
        <Field label="Source type" wide><select value={sourceType} onChange={event => setSourceType(event.target.value)}><option value="AzureMigrateServerReport">Azure Migrate Server Report</option><option value="AzureMigrateAllInventoryReport">Azure Migrate All Inventory Report</option></select><small>The selected source is verified against report headers; conflicting files are rejected.</small></Field>
        <Field label="Discovery file" wide><input type="file" accept=".csv,text/csv" onChange={event => setFile(event.target.files?.[0] ?? null)} /><small>UTF-8 comma-separated CSV, maximum 25 MB. Quoted values and embedded commas are supported.</small></Field>
      </div>
      <div className="import-notice"><strong>Preview first</strong><span>Upload stores a generated server-side file and stages source rows as JSON. It does not update canonical inventory.</span></div>
      <FieldError value={error} />
      <div className="form-actions"><Link className="button secondary" href="/discovery/imports">Cancel</Link><button className="button primary" disabled={saving}>{saving ? "Uploading and previewing…" : "Upload and preview"}</button></div>
    </form>
  </>;
}
