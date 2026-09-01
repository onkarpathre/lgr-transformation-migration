"use client";

import { useEffect, useState } from "react";
import { useApi } from "@/components/ApiContext";
import { Badge, Field, FieldError, FormActions, LoadState, Modal, PageHeader, formatDate, useData, useSubmit } from "@/components/ui";
import { Application, Paged, Server, Wave, WaveDetail } from "@/types/api";

const blank = { name: "", plannedDate: "", status: "Planning", description: "" };

export default function WavesPage() {
  const { api } = useApi(); const waves = useData<Wave[]>("/api/migration-waves"); const [selected, setSelected] = useState(""); const [open, setOpen] = useState(false); const [form, setForm] = useState(blank);
  const { saving, formError, submit } = useSubmit(() => { setOpen(false); setForm(blank); void waves.reload(); });
  useEffect(() => { if (!selected && waves.data?.length) setSelected(waves.data[0].id); }, [selected, waves.data]);
  return <><PageHeader eyebrow="Migration" title="Migration Waves" description="Group applications and servers into governed cutover events." action={<button className="button primary" onClick={() => setOpen(true)}>New wave</button>} />
    <LoadState loading={waves.loading} error={waves.error}><div className="waves-layout"><div className="wave-cards">{waves.data?.map(w => <button key={w.id} className={`wave-card ${selected === w.id ? "selected" : ""}`} onClick={() => setSelected(w.id)}><div><p className="eyebrow">{formatDate(w.plannedDate)}</p><Badge value={w.status} /></div><h2>{w.name}</h2><p>{w.description}</p><div className="wave-counts"><span><strong>{w.applications}</strong>Apps</span><span><strong>{w.servers}</strong>Servers</span><span><strong>{w.ready}</strong>Ready</span><span><strong>{w.blocked}</strong>Blocked</span></div></button>)}</div>{selected && <WaveDetails id={selected} />}</div></LoadState>
    {open && <Modal title="Create migration wave" onClose={() => setOpen(false)}><form onSubmit={e => submit(e, () => api("/api/migration-waves", { method: "POST", body: JSON.stringify(form) }))}><div className="form-grid"><Field label="Wave name" wide><input required value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></Field><Field label="Planned date"><input type="date" value={form.plannedDate} onChange={e => setForm({ ...form, plannedDate: e.target.value })} /></Field><Field label="Status"><select value={form.status} onChange={e => setForm({ ...form, status: e.target.value })}>{["Not Started","Planning","Ready","In Progress","Completed","Blocked"].map(x => <option key={x}>{x}</option>)}</select></Field><Field label="Description" wide><textarea value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} /></Field></div><FieldError value={formError} /><FormActions saving={saving} onCancel={() => setOpen(false)} /></form></Modal>}
  </>;
}

function WaveDetails({ id }: { id: string }) {
  const { api } = useApi(); const detail = useData<WaveDetail>(`/api/migration-waves/${id}`); const apps = useData<Paged<Application>>("/api/applications?pageSize=200"); const servers = useData<Paged<Server>>("/api/servers?pageSize=200");
  const [assetType, setAssetType] = useState("Application"); const [assetId, setAssetId] = useState(""); const [message, setMessage] = useState("");
  useEffect(() => { setAssetId(""); }, [assetType, id]);
  const add = async () => { setMessage(""); try { await api(`/api/migration-waves/${id}/assets`, { method: "POST", body: JSON.stringify(assetType === "Application" ? { applicationId: assetId, status: "Planned" } : { serverId: assetId, status: "Planned" }) }); setAssetId(""); await detail.reload(); } catch (e) { setMessage(e instanceof Error ? e.message : "Unable to add asset"); } };
  return <div className="panel wave-detail"><LoadState loading={detail.loading} error={detail.error}>{detail.data && <><div className="panel-title"><div><p className="eyebrow">Wave detail</p><h2>{detail.data.wave.name}</h2></div><Badge value={detail.data.wave.status} /></div><div className="asset-adder"><select value={assetType} onChange={e => setAssetType(e.target.value)}><option>Application</option><option>Server</option></select><select value={assetId} onChange={e => setAssetId(e.target.value)}><option value="">Select {assetType.toLowerCase()}</option>{assetType === "Application" ? apps.data?.items.map(x => <option value={x.id} key={x.id}>{x.name}</option>) : servers.data?.items.map(x => <option value={x.id} key={x.id}>{x.hostname}</option>)}</select><button className="button small" disabled={!assetId} onClick={add}>Add to wave</button></div>{message && <p className="form-error">{message}</p>}<div className="table-wrap flat"><table><thead><tr><th>Asset</th><th>Type</th><th>Plan status</th><th>Readiness</th></tr></thead><tbody>{detail.data.assets.map(x => <tr key={x.id}><td><strong>{x.assetName}</strong></td><td>{x.assetType}</td><td><Badge value={x.status} /></td><td><Badge value={x.overallReadiness} /></td></tr>)}</tbody></table></div></>}</LoadState></div>;
}
