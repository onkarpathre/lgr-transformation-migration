"use client";

import Link from "next/link";
import { FormEvent, useCallback, useEffect, useRef, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { ApiError, useApi } from "@/components/ApiContext";
import { Badge, Field, LoadState, PageHeader, StatusMessage, formatDate } from "@/components/ui";
import { Dependency, DependencyAuditEvent, Paged } from "@/types/api";

const dependencyTypes = ["Service", "DataRead", "DataWrite", "ApiCall", "FileTransfer", "Authentication", "NetworkConnectivity", "OperationalSequence"];

export default function DependencyDetailPage() {
  const { id } = useParams<{ id: string }>(); const router = useRouter();
  const { api, apiResponse, hasPermission } = useApi();
  const [dependency, setDependency] = useState<Dependency | null>(null); const [etag, setEtag] = useState("");
  const [audit, setAudit] = useState<DependencyAuditEvent[]>([]); const [loading, setLoading] = useState(true);
  const [error, setError] = useState(""); const [message, setMessage] = useState(""); const [saving, setSaving] = useState(false);
  const [dependencyType, setDependencyType] = useState("Service"); const [criticality, setCriticality] = useState("Mandatory");
  const [description, setDescription] = useState(""); const [businessContext, setBusinessContext] = useState("");
  const errorSummary = useRef<HTMLDivElement>(null);
  const canManage = hasPermission("dependency.manage"); const canConfirm = hasPermission("dependency.confirm"); const canAudit = hasPermission("dependency.audit.read");

  const load = useCallback(async () => {
    setLoading(true); setError("");
    try {
      const result = await apiResponse<Dependency>(`/api/v1/dependencies/${id}`);
      setDependency(result.data); setEtag(result.etag ?? `"${result.data.version}"`);
      setDependencyType(result.data.dependencyType); setCriticality(result.data.criticality); setDescription(result.data.description ?? ""); setBusinessContext(result.data.businessContext ?? "");
      if (canAudit) setAudit((await api<Paged<DependencyAuditEvent>>(`/api/v1/dependencies/${id}/audit?pageSize=50`)).items);
    } catch (caught) { setError(caught instanceof Error ? caught.message : "Unable to load dependency"); }
    finally { setLoading(false); }
  }, [api, apiResponse, canAudit, id]);
  useEffect(() => { void load(); }, [load]);

  const fail = (caught: unknown) => {
    const apiError = caught instanceof ApiError ? caught : null;
    setError(apiError?.status === 412 ? "This dependency changed after you opened it. Your entered values are retained; reload before applying them again." : caught instanceof Error ? caught.message : "Unable to save dependency");
    requestAnimationFrame(() => errorSummary.current?.focus());
  };
  const update = async (event: FormEvent) => {
    event.preventDefault(); setSaving(true); setError(""); setMessage("");
    try {
      const result = await apiResponse<Dependency>(`/api/v1/dependencies/${id}`, { method: "PUT", headers: { "If-Match": etag }, body: JSON.stringify({ dependencyType, criticality, description, businessContext }) });
      setDependency(result.data); setEtag(result.etag ?? `"${result.data.version}"`); setMessage("Dependency updated.");
    } catch (caught) { fail(caught); } finally { setSaving(false); }
  };
  const setConfirmation = async (status: "Confirmed" | "Unconfirmed") => {
    setSaving(true); setError(""); setMessage("");
    try {
      const result = await apiResponse<Dependency>(`/api/v1/dependencies/${id}/confirmation`, { method: "PUT", headers: { "If-Match": etag }, body: JSON.stringify({ confirmationStatus: status }) });
      setDependency(result.data); setEtag(result.etag ?? `"${result.data.version}"`); setMessage(`Dependency ${status.toLowerCase()}.`); if (canAudit) setAudit((await api<Paged<DependencyAuditEvent>>(`/api/v1/dependencies/${id}/audit?pageSize=50`)).items);
    } catch (caught) { fail(caught); } finally { setSaving(false); }
  };
  const archive = async () => {
    if (!window.confirm("Archive this dependency? It cannot be restored in Phase 4.")) return;
    setSaving(true); setError("");
    try { await api(`/api/v1/dependencies/${id}`, { method: "DELETE", headers: { "If-Match": etag } }); router.push("/planning/dependencies"); }
    catch (caught) { fail(caught); setSaving(false); }
  };

  return <>
    <PageHeader eyebrow="Planning / Dependencies / Detail" title="Dependency detail" description="Review the explicit source-depends-on-target relationship, confirmation and safe audit history." action={<Link className="button secondary" href="/planning/dependencies">Back to register</Link>} />
    <LoadState loading={loading} error={!dependency ? error : ""} onRetry={load}>
      {dependency && <>
        <div ref={errorSummary} tabIndex={-1}><StatusMessage message={error} error /><StatusMessage message={message} /></div>
        <section className="panel"><h2>Relationship</h2><div className="stats"><div><small>Dependent source</small><strong>{dependency.source.displayName}</strong><span>{dependency.source.type}</span></div><div><small>Direction</small><strong>Depends on</strong><span>Source requires target</span></div><div><small>Provider target</small><strong>{dependency.target.displayName}</strong><span>{dependency.target.referenceType ?? dependency.target.type}{dependency.target.resolutionStatus ? ` · ${dependency.target.resolutionStatus}` : ""}</span></div></div><p><Badge value={dependency.confirmationStatus} /> <Badge value={dependency.criticality} /></p>{dependency.confirmedAt && <p>Confirmed {formatDate(dependency.confirmedAt)} by {dependency.confirmedByDisplay}</p>}</section>
        <form className="panel form-grid" onSubmit={update}><h2 className="wide">Planning context</h2><Field label="Dependency type"><select disabled={!canManage || saving} value={dependencyType} onChange={event => setDependencyType(event.target.value)}>{dependencyTypes.map(value => <option key={value}>{value}</option>)}</select></Field><Field label="Criticality"><select disabled={!canManage || saving} value={criticality} onChange={event => setCriticality(event.target.value)}><option>Mandatory</option><option>Advisory</option></select></Field><Field label="Description" wide><textarea disabled={!canManage || saving} maxLength={2000} value={description} onChange={event => setDescription(event.target.value)} /></Field><Field label="Business context" wide><textarea disabled={!canManage || saving} maxLength={4000} value={businessContext} onChange={event => setBusinessContext(event.target.value)} /></Field><div className="form-actions wide">{canConfirm && <button type="button" className="button secondary" disabled={saving} onClick={() => void setConfirmation(dependency.confirmationStatus === "Confirmed" ? "Unconfirmed" : "Confirmed")}>{dependency.confirmationStatus === "Confirmed" ? "Mark unconfirmed" : "Confirm dependency"}</button>}{canManage && <><button type="button" className="button secondary" disabled={saving} onClick={() => void archive()}>Archive</button><button className="button primary" disabled={saving}>{saving ? "Saving…" : "Save changes"}</button></>}</div></form>
        {canAudit && <section className="panel"><h2>Significant-change audit</h2>{audit.length ? <div className="table-wrap"><table><caption>Dependency audit events</caption><thead><tr><th>Action</th><th>Actor</th><th>Timestamp</th><th>Correlation</th></tr></thead><tbody>{audit.map(item => <tr key={item.id}><td>{item.action}</td><td>{item.changedBy}</td><td>{formatDate(item.changedAt)}</td><td><code>{item.correlationId ?? "—"}</code></td></tr>)}</tbody></table></div> : <p>No significant changes recorded.</p>}</section>}
      </>}
    </LoadState>
  </>;
}
