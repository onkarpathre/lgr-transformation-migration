"use client";

import { useState } from "react";
import { useApi } from "@/components/ApiContext";
import { Badge, LoadState, PageHeader, formatDate, useData } from "@/components/ui";
import { Ip, Paged, Server, Subnet } from "@/types/api";

export default function IpManagementPage() {
  const { api } = useApi(); const subnets = useData<Subnet[]>("/api/subnets"); const ips = useData<Ip[]>("/api/ip-addresses"); const { data: servers } = useData<Paged<Server>>("/api/servers?pageSize=200");
  const [selectedSubnet, setSelectedSubnet] = useState(""); const [serverId, setServerId] = useState(""); const [actionError, setActionError] = useState(""); const [busy, setBusy] = useState("");
  const visibleIps = ips.data?.filter(x => !selectedSubnet || x.subnetId === selectedSubnet) ?? [];
  const transition = async (ip: Ip, action: "reserve" | "allocate" | "release") => {
    setBusy(ip.id); setActionError("");
    try { await api(`/api/ip-addresses/${ip.id}/${action}`, { method: "POST", body: action === "reserve" ? JSON.stringify({ serverId }) : undefined }); await Promise.all([ips.reload(), subnets.reload()]); }
    catch (e) { setActionError(e instanceof Error ? e.message : "Transition failed"); } finally { setBusy(""); }
  };
  return <><PageHeader eyebrow="Azure design" title="IP Management" description="Controlled reservation and allocation of the sample Azure address pools." />
    <LoadState loading={subnets.loading || ips.loading} error={subnets.error || ips.error}>
      <section className="subnet-grid">{subnets.data?.map(x => <button className={`subnet-card ${selectedSubnet === x.id ? "selected" : ""}`} key={x.id} onClick={() => setSelectedSubnet(selectedSubnet === x.id ? "" : x.id)}><div><span className="network-icon">NET</span><Badge value={x.environment} /></div><h2>{x.name}</h2><p>{x.vNetName}</p><code>{x.cidr}</code><div className="capacity"><span><strong>{x.totalAddresses}</strong>Total</span><span><strong>{x.available}</strong>Available</span><span><strong>{x.reserved}</strong>Reserved</span><span><strong>{x.allocated}</strong>Allocated</span></div></button>)}</section>
      <div className="panel ip-panel"><div className="panel-title"><div><p className="eyebrow">Address records</p><h2>{selectedSubnet ? subnets.data?.find(x => x.id === selectedSubnet)?.name : "All subnets"}</h2></div><label className="compact-field">Reserve for server<select value={serverId} onChange={e => setServerId(e.target.value)}><option value="">Select server</option>{servers?.items.map(x => <option value={x.id} key={x.id}>{x.hostname}</option>)}</select></label></div>{actionError && <p className="form-error">{actionError}</p>}<div className="table-wrap flat"><table><thead><tr><th>IP address</th><th>Subnet</th><th>Status</th><th>Server</th><th>Reservation date</th><th>Allocation date</th><th>Next action</th></tr></thead><tbody>{visibleIps.map(ip => <tr key={ip.id}><td className="mono"><strong>{ip.address}</strong></td><td>{ip.subnetName}</td><td><Badge value={ip.status} /></td><td>{ip.serverName ?? "—"}</td><td>{formatDate(ip.reservedAt)}</td><td>{formatDate(ip.allocatedAt)}</td><td>{ip.status === "Available" && <button disabled={!serverId || busy === ip.id} className="button small" onClick={() => transition(ip, "reserve")}>Reserve</button>}{ip.status === "Reserved" && <button disabled={busy === ip.id} className="button small" onClick={() => transition(ip, "allocate")}>Allocate</button>}{ip.status === "Allocated" && <button disabled={busy === ip.id} className="button small danger" onClick={() => transition(ip, "release")}>Release</button>}</td></tr>)}</tbody></table></div></div>
    </LoadState>
  </>;
}
