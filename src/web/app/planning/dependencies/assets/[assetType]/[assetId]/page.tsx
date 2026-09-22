"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { Badge, Empty, LoadState, PageHeader, useData } from "@/components/ui";
import { Dependency, Paged } from "@/types/api";

export default function AssetDependenciesPage() {
  const { assetType, assetId } = useParams<{ assetType: string; assetId: string }>();
  const state = useData<Paged<Dependency>>(`/api/v1/dependencies?assetType=${encodeURIComponent(assetType)}&assetId=${encodeURIComponent(assetId)}&direction=Either&pageSize=200`);
  const items = state.data?.items ?? [];
  return <>
    <PageHeader eyebrow="Planning / Dependencies / Asset" title="Asset dependencies" description="Both directions for this authorised project asset, labelled explicitly as Depends on or Required by." action={<Link className="button secondary" href="/planning/dependencies">Back to register</Link>} />
    <LoadState loading={state.loading} error={state.error} onRetry={state.reload}>{items.length ? <div className="table-wrap"><table><caption>Relationships for the selected asset</caption><thead><tr><th>Direction</th><th>Related endpoint</th><th>Type</th><th>Criticality</th><th>Status</th><th /></tr></thead><tbody>{items.map(item => { const isSource = item.source.type === assetType && item.source.id === assetId; const related = isSource ? item.target : item.source; return <tr key={item.id}><td>{isSource ? "Depends on" : "Required by"}</td><td><strong>{related.displayName}</strong><small>{related.referenceType ?? related.type}</small></td><td>{item.dependencyType}</td><td><Badge value={item.criticality} /></td><td><Badge value={item.confirmationStatus} /></td><td><Link className="text-button" href={`/planning/dependencies/${item.id}`}>View details</Link></td></tr>; })}</tbody></table></div> : <Empty message="No dependencies are recorded for this asset." />}</LoadState>
  </>;
}
