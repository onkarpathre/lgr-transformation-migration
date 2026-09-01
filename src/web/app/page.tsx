"use client";

import { Badge, LoadState, PageHeader, formatDate, useData } from "@/components/ui";
import { Dashboard } from "@/types/api";
import Link from "next/link";

export default function DashboardPage() {
  const { data, loading, error } = useData<Dashboard>("/api/dashboard/summary");
  const cards = data ? [
    ["Applications", data.totalApplications, `${data.applicationsInScope} in scope`, "AP"],
    ["Servers", data.totalServers, `${data.serversMigrated} migrated`, "SV"],
    ["Migration Waves", data.migrationWaves, "Programme schedule", "WV"],
    ["Ready", data.readyAssets, "Assets cleared", "RD"],
    ["Blocked", data.blockedAssets, "Require action", "BL"],
    ["Migrated", data.applicationsMigrated + data.serversMigrated, "Apps and servers", "MG"],
    ["Available IPs", data.availableIpAddresses, `${data.reservedIpAddresses} reserved`, "IP"]
  ] : [];
  return <>
    <PageHeader eyebrow="Programme control" title="Dashboard" description="A live view of migration scope, readiness and delivery progress." />
    <LoadState loading={loading} error={error}>
      {data && <>
        <section className="metric-grid">{cards.map(([label, value, note, icon]) => <article className="metric-card" key={label}><div className="metric-icon">{icon}</div><div><p>{label}</p><strong>{value}</strong><small>{note}</small></div></article>)}</section>
        <section className="dashboard-grid">
          <article className="panel">
            <div className="panel-title"><div><p className="eyebrow">Delivery plan</p><h2>Migration waves</h2></div><span className="muted">{data.waves.length} waves</span></div>
            <div className="wave-list">{data.waves.map(wave => <div className="wave-row" key={wave.id}><div className="date-tile"><strong>{wave.plannedDate ? new Date(wave.plannedDate).getDate() : "—"}</strong><small>{wave.plannedDate ? new Intl.DateTimeFormat("en-GB", { month: "short" }).format(new Date(wave.plannedDate)) : "TBC"}</small></div><div className="grow"><strong>{wave.name}</strong><small>{wave.applications} applications · {wave.servers} servers · {formatDate(wave.plannedDate)}</small></div><div className="readiness-mini"><span><b>{wave.ready}</b> ready</span><span><b>{wave.blocked}</b> blocked</span></div><Badge value={wave.status} /></div>)}</div>
          </article>
          <article className="panel">
            <div className="panel-title"><div><p className="eyebrow">Portfolio</p><h2>Application status</h2></div></div>
            <div className="status-bars">{Object.entries(data.applicationMigrationStatus).map(([status, count]) => { const pct = data.totalApplications ? Math.round(count / data.totalApplications * 100) : 0; return <div key={status}><div><span>{status}</span><strong>{count}</strong></div><span className="bar"><i style={{ width: `${pct}%` }} /></span></div>; })}</div>
            <div className="ip-summary"><p className="eyebrow">IP capacity</p><div><span><strong>{data.availableIpAddresses}</strong>Available</span><span><strong>{data.reservedIpAddresses}</strong>Reserved</span><span><strong>{data.allocatedIpAddresses}</strong>Allocated</span></div></div>
          </article>
        </section>
        <section className="panel discovery-dashboard">
          <div className="panel-title"><div><p className="eyebrow">Discovery</p><h2>Latest infrastructure import</h2></div><Link className="text-button" href={data.discovery ? `/discovery/imports/${data.discovery.importBatchId}` : "/discovery/imports"}>Import history</Link></div>
          {data.discovery ? <div className="discovery-dashboard-grid"><span><small>Last discovery import</small><strong>{formatDate(data.discovery.importDate)}</strong></span><span><small>Last import status</small><Badge value={data.discovery.status} /></span><span><small>Servers discovered</small><strong>{data.discovery.serversDiscovered}</strong></span><span><small>Created</small><strong>{data.discovery.created}</strong></span><span><small>Updated</small><strong>{data.discovery.updated}</strong></span><span><small>Warnings / rejects</small><strong>{data.discovery.warnings} / {data.discovery.rejects}</strong></span></div> : <p className="muted">No discovery report has been uploaded for this project.</p>}
        </section>
      </>}
    </LoadState>
  </>;
}
