"use client";

import Link from "next/link";
import { useState } from "react";
import { useApi } from "@/components/ApiContext";
import { Badge, Empty, LoadState, PageHeader, Pagination, useData } from "@/components/ui";
import { Dependency, Paged } from "@/types/api";

const dependencyTypes = ["Service", "DataRead", "DataWrite", "ApiCall", "FileTransfer", "Authentication", "NetworkConnectivity", "OperationalSequence"];

export default function DependenciesPage() {
  const { hasPermission } = useApi();
  const canManage = hasPermission("dependency.manage");
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [type, setType] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const state = useData<Paged<Dependency>>(`/api/v1/dependencies?page=${page}&pageSize=50&search=${encodeURIComponent(search)}&dependencyType=${encodeURIComponent(type)}&confirmationStatus=${encodeURIComponent(confirmation)}`);
  const items = state.data?.items ?? [];

  return <>
    <PageHeader
      eyebrow="Planning / Dependencies"
      title="Dependency register"
      description="Human-governed planning relationships. A source depends on its target; records never call or execute against either endpoint."
      action={canManage ? <Link className="button primary" href="/planning/dependencies/new">Add dependency</Link> : undefined}
    />
    <div className="toolbar">
      <label className="search"><span aria-hidden="true">⌕</span><input aria-label="Search dependencies" value={search} onChange={event => { setSearch(event.target.value); setPage(1); }} placeholder="Search dependencies" /></label>
      <label className="compact-field">Type<select value={type} onChange={event => { setType(event.target.value); setPage(1); }}><option value="">All</option>{dependencyTypes.map(value => <option key={value}>{value}</option>)}</select></label>
      <label className="compact-field">Confirmation<select value={confirmation} onChange={event => { setConfirmation(event.target.value); setPage(1); }}><option value="">All</option><option>Confirmed</option><option>Unconfirmed</option></select></label>
      <span>{state.data?.totalCount ?? 0} dependencies</span>
    </div>
    <LoadState loading={state.loading} error={state.error} onRetry={state.reload}>
      {items.length ? <>
        <div className="table-wrap"><table><caption>Dependencies in the active project</caption><thead><tr><th>Dependent source</th><th>Direction</th><th>Provider target</th><th>Type</th><th>Criticality</th><th>Confirmation</th><th /></tr></thead><tbody>
          {items.map(item => <tr key={item.id}><td><strong>{item.source.displayName}</strong><small>{item.source.type}</small></td><td>Depends on</td><td><strong>{item.target.displayName}</strong><small>{item.target.referenceType ?? item.target.type}{item.target.resolutionStatus ? ` · ${item.target.resolutionStatus}` : ""}</small></td><td>{item.dependencyType}</td><td><Badge value={item.criticality} /></td><td><Badge value={item.confirmationStatus} /></td><td><Link className="text-button" href={`/planning/dependencies/${item.id}`}>View details</Link></td></tr>)}
        </tbody></table></div>
        <Pagination page={state.data?.page ?? page} pageSize={state.data?.pageSize ?? 50} totalCount={state.data?.totalCount ?? 0} onPage={setPage} />
      </> : <Empty message="No dependencies match this view." action={canManage ? <Link className="button secondary" href="/planning/dependencies/new">Add the first dependency</Link> : undefined} />}
    </LoadState>
  </>;
}
