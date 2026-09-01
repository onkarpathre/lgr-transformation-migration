"use client";

import { Badge, LoadState, PageHeader, useData } from "@/components/ui";
import { Target } from "@/types/api";

export default function TargetBuildsPage() {
  const { data, loading, error } = useData<Target[]>("/api/azure-targets");
  return <><PageHeader eyebrow="Azure design" title="Target Builds" description="Approved Azure landing-zone details mapped back to the source server." />
    <LoadState loading={loading} error={error}><div className="target-grid">{data?.map(x => <article className="target-card" key={x.id}><div className="target-card-head"><div><p className="eyebrow">{x.serverName}</p><h2>{x.azureHostname}</h2></div><Badge value="Defined" /></div><dl><div><dt>Azure IP</dt><dd className="mono">{x.azureIp}</dd></div><div><dt>VM size</dt><dd>{x.vmSize}</dd></div><div><dt>Subscription</dt><dd>{x.subscription}</dd></div><div><dt>Resource group</dt><dd>{x.resourceGroup}</dd></div><div><dt>VNet</dt><dd>{x.vNet}</dd></div><div><dt>Subnet</dt><dd>{x.subnet}</dd></div><div><dt>Operating system</dt><dd>{x.operatingSystem}</dd></div><div><dt>Backup policy</dt><dd>{x.backupPolicy}</dd></div><div><dt>Domain</dt><dd>{x.domain}</dd></div><div><dt>Organisational unit</dt><dd>{x.organisationalUnit}</dd></div></dl>{x.notes && <p className="target-notes">{x.notes}</p>}</article>)}</div></LoadState>
  </>;
}
