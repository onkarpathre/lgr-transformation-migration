"use client";

import Link from "next/link";
import { useMemo } from "react";
import { useApi } from "@/components/ApiContext";
import { Badge, Empty, LoadState, PageHeader, formatDate, useData } from "@/components/ui";
import { DiscoveryImport, Paged } from "@/types/api";

const sourceNames: Record<string, string> = { AzureMigrateAllInventoryReport: "Azure Migrate All Inventory", AzureMigrateServerReport: "Azure Migrate Server Report", SqlInstanceCsvV1: "SQL instance CSV v1", SqlDatabaseCsvV1: "SQL database CSV v1" };

export default function DiscoveryImportsPage() {
  const { hasPermission, capabilitiesLoading } = useApi();
  const legacy = useData<DiscoveryImport[]>("/api/discovery/imports");
  const sql = useData<Paged<DiscoveryImport>>(hasPermission("sql.discovery.read") ? "/api/v1/discovery/imports?pageSize=200" : null);
  const data = useMemo(() => [...(legacy.data ?? []), ...(sql.data?.items ?? [])].sort((a, b) => b.uploadedAt.localeCompare(a.uploadedAt)), [legacy.data, sql.data]);
  const loading = capabilitiesLoading || legacy.loading || sql.loading; const error = legacy.error || sql.error;
  return <><PageHeader eyebrow="Discovery / Imports" title="Imports" description="Upload, preview and reconcile approved file-based discovery sources before changing inventory." action={<Link className="button primary" href="/discovery/imports/new">New import</Link>} />
    <LoadState loading={loading} error={error} onRetry={() => { void legacy.reload(); void sql.reload(); }}>{data.length ? <div className="table-wrap"><table><caption>Discovery import batches for the active project</caption><thead><tr><th>Import date</th><th>File name</th><th>Source type</th><th>Status</th><th>Total</th><th>Create</th><th>Update</th><th>Unchanged</th><th>Warnings</th><th>Rejected</th><th>Uploaded by</th><th /></tr></thead><tbody>
      {data.map(batch => <tr key={`${batch.sourceType}-${batch.id}`}><td>{formatDate(batch.committedAt ?? batch.uploadedAt)}</td><td><strong>{batch.originalFileName}</strong><small className="mono">{batch.fileHash.slice(0, 12)}…</small></td><td>{sourceNames[batch.sourceType] ?? batch.sourceType}</td><td><Badge value={batch.status} /></td><td>{batch.totalRows}</td><td>{batch.createCount}</td><td>{batch.updateCount}</td><td>{batch.unchangedCount}</td><td>{batch.warningCount}</td><td>{batch.rejectCount}</td><td>{batch.uploadedBy}</td><td><Link className="text-button" href={`/discovery/imports/${batch.id}`}>View</Link></td></tr>)}
    </tbody></table></div> : <Empty message="No discovery imports have been uploaded for this project." action={<Link className="button secondary" href="/discovery/imports/new">Upload a CSV</Link>} />}</LoadState>
  </>;
}
