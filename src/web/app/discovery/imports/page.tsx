"use client";

import Link from "next/link";
import { Badge, Empty, LoadState, PageHeader, formatDate, useData } from "@/components/ui";
import { DiscoveryImport } from "@/types/api";

const sourceName = (value: string) => value === "AzureMigrateAllInventoryReport" ? "Azure Migrate All Inventory" : "Azure Migrate Server Report";

export default function DiscoveryImportsPage() {
  const { data, loading, error } = useData<DiscoveryImport[]>("/api/discovery/imports");
  return <>
    <PageHeader eyebrow="Discovery" title="Imports" description="Upload, preview and reconcile Azure Migrate discovery reports without silently changing inventory." action={<Link className="button primary" href="/discovery/imports/new">New import</Link>} />
    <LoadState loading={loading} error={error}>
      {data?.length ? <div className="table-wrap"><table><thead><tr><th>Import date</th><th>File name</th><th>Source type</th><th>Status</th><th>Total</th><th>Create</th><th>Update</th><th>Unchanged</th><th>Warnings</th><th>Rejected</th><th>Uploaded by</th><th /></tr></thead><tbody>
        {data.map(batch => <tr key={batch.id}><td>{formatDate(batch.committedAt ?? batch.uploadedAt)}</td><td><strong>{batch.originalFileName}</strong><small className="mono">{batch.fileHash.slice(0, 12)}…</small></td><td>{sourceName(batch.sourceType)}</td><td><Badge value={batch.status} /></td><td>{batch.totalRows}</td><td>{batch.createCount}</td><td>{batch.updateCount}</td><td>{batch.unchangedCount}</td><td>{batch.warningCount}</td><td>{batch.rejectCount}</td><td>{batch.uploadedBy}</td><td><Link className="text-button" href={`/discovery/imports/${batch.id}`}>View</Link></td></tr>)}
      </tbody></table></div> : <Empty message="No discovery imports have been uploaded for this project." />}
    </LoadState>
  </>;
}
