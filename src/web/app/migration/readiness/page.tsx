"use client";

import { useState } from "react";
import { useApi } from "@/components/ApiContext";
import { Badge, LoadState, PageHeader, useData } from "@/components/ui";
import { ReadinessResponse } from "@/types/api";

const statuses = ["NotStarted", "Complete", "AtRisk", "Blocked", "NotApplicable"];

export default function ReadinessPage() {
  const { api } = useApi(); const readiness = useData<ReadinessResponse>("/api/readiness"); const [filter, setFilter] = useState(""); const [error, setError] = useState("");
  const update = async (id: string, status: string, comment: string) => { setError(""); try { await api(`/api/readiness/${id}`, { method: "PUT", body: JSON.stringify({ status, comment }) }); await readiness.reload(); } catch (e) { setError(e instanceof Error ? e.message : "Unable to update check"); } };
  const checks = readiness.data?.checks.filter(x => !filter || x.overallStatus === filter) ?? [];
  return <>
    <PageHeader eyebrow="Migration" title="Readiness" description="Deterministic readiness controls across applications, servers and migration waves." />
    <LoadState loading={readiness.loading} error={readiness.error}>
      {readiness.data && <>
        <section className="readiness-summary">
          {readiness.data.waves.map(x => <article key={x.waveId}>
            <p>{x.waveName}</p>
            <strong>{x.ready}<small> / {x.totalAssets} ready</small></strong>
            <div>
              <span className="ready-segment" style={{ width: `${x.totalAssets ? x.ready / x.totalAssets * 100 : 0}%` }} />
              <span className="risk-segment" style={{ width: `${x.totalAssets ? x.atRisk / x.totalAssets * 100 : 0}%` }} />
              <span className="blocked-segment" style={{ width: `${x.totalAssets ? x.blocked / x.totalAssets * 100 : 0}%` }} />
            </div>
            <small>{x.atRisk} conditional &middot; {x.blocked} blocked &middot; {x.notReady} not ready</small>
          </article>)}
        </section>
        <div className="toolbar">
          <select value={filter} onChange={e => setFilter(e.target.value)}>
            <option value="">All overall statuses</option>
            {["NotReady", "AtRisk", "ReadyWithConditions", "Ready", "Blocked"].map(x => <option key={x}>{x}</option>)}
          </select>
          <span>{checks.length} checks</span>
        </div>
        {error && <p className="form-error">{error}</p>}
        <div className="table-wrap"><table>
          <thead><tr><th>Asset</th><th>Type</th><th>Check</th><th>Check status</th><th>Comment</th><th>Overall</th></tr></thead>
          <tbody>{checks.map(x => <tr key={x.id}>
            <td><strong>{x.assetName}</strong></td><td>{x.assetType}</td>
            <td>{x.checkType.replace(/([A-Z])/g, " $1").trim()}</td>
            <td><select className="status-select" value={x.status} onChange={e => update(x.id, e.target.value, x.comment)}>{statuses.map(s => <option key={s}>{s}</option>)}</select></td>
            <td className="wide-cell">{x.comment}</td><td><Badge value={x.overallStatus} /></td>
          </tr>)}</tbody>
        </table></div>
      </>}
    </LoadState>
  </>;
}
