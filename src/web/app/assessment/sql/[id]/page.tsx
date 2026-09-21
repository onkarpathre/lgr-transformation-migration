"use client";

import Link from "next/link";
import { FormEvent, useEffect, useRef, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { ApiError, useApi } from "@/components/ApiContext";
import { Badge, Field, LoadState, PageHeader, StatusMessage, useData } from "@/components/ui";
import { SqlAssessment } from "@/types/api";

const assessmentStatuses = ["NotStarted", "InProgress", "Complete", "Blocked"];
const readinessStatuses = ["NotAssessed", "NotReady", "AtRisk", "ReadyWithConditions", "Ready", "Blocked"];
const platforms = ["", "AzureSqlDatabase", "AzureSqlManagedInstance", "SqlServerOnAzureVm", "Retain", "Retire", "Investigate"];
const approaches = ["", "Offline", "Online", "ToBeDetermined", "NotApplicable"];

export default function SqlAssessmentDetailPage() {
  const { id } = useParams<{ id: string }>(); const router = useRouter(); const { api, hasPermission } = useApi(); const state = useData<SqlAssessment>(`/api/v1/sql-assessments/${id}`);
  const [evidence, setEvidence] = useState({ assessmentStatus: "NotStarted", readinessStatus: "NotAssessed", blockers: "", findings: "", notes: "", assessedAt: "" }); const [planning, setPlanning] = useState({ targetPlatform: "", targetSqlVersion: "", migrationApproach: "" }); const [message, setMessage] = useState(""); const [error, setError] = useState(""); const [saving, setSaving] = useState(false);
  const outcome = useRef<HTMLDivElement>(null);
  useEffect(() => { if (state.data) { setEvidence({ assessmentStatus: state.data.assessmentStatus, readinessStatus: state.data.readinessStatus, blockers: state.data.blockers, findings: state.data.findings, notes: state.data.notes, assessedAt: state.data.assessedAt ? state.data.assessedAt.slice(0, 16) : "" }); setPlanning({ targetPlatform: state.data.targetPlatform ?? "", targetSqlVersion: state.data.targetSqlVersion ?? "", migrationApproach: state.data.migrationApproach ?? "" }); } }, [state.data]);
  const save = async (event: FormEvent, kind: "evidence" | "planning") => {
    event.preventDefault(); if (!state.data) return; setError(""); setMessage("");
    const validation = kind === "evidence" ? validateEvidence(evidence, planning) : validatePlanning(state.data.assessmentStatus, planning);
    if (validation) { setError(validation); requestAnimationFrame(() => outcome.current?.focus()); return; }
    setSaving(true);
    try {
      const body = kind === "evidence" ? { ...evidence, assessedAt: evidence.assessedAt ? new Date(evidence.assessedAt).toISOString() : null } : { targetPlatform: planning.targetPlatform || null, targetSqlVersion: planning.targetSqlVersion.trim() || null, migrationApproach: planning.migrationApproach || null };
      await api(`/api/v1/sql-assessments/${id}/${kind}`, { method: "PUT", headers: { "If-Match": `"${state.data.version}"` }, body: JSON.stringify(body) }); setMessage(kind === "evidence" ? "Assessment evidence saved." : "Human planning values saved."); await state.reload();
    } catch (exception) { if (exception instanceof ApiError && exception.status === 412) { setError("This assessment changed. The latest values have been loaded; review them before saving again."); await state.reload(); } else setError(exception instanceof Error ? exception.message : "Unable to save the assessment."); }
    finally { setSaving(false); requestAnimationFrame(() => outcome.current?.focus()); }
  };
  const archive = async () => { if (!state.data || !window.confirm("Archive this assessment? The SQL inventory target will not be archived.")) return; setSaving(true); setError(""); try { await api(`/api/v1/sql-assessments/${id}`, { method: "DELETE", headers: { "If-Match": `"${state.data.version}"` } }); router.push("/assessment/sql"); } catch (exception) { setError(exception instanceof ApiError && exception.status === 412 ? "This assessment changed. Refresh and review before archiving." : exception instanceof Error ? exception.message : "Unable to archive the assessment."); if (exception instanceof ApiError && exception.status === 412) await state.reload(); } finally { setSaving(false); } };
  const targetHref = state.data?.targetType === "SqlInstance" ? `/inventory/sql-instances/${state.data.target.id}` : `/inventory/sql-databases/${state.data?.target.id}`;
  return <><PageHeader eyebrow="Assessment / SQL / Detail" title={state.data?.target.name ?? "SQL assessment"} description="Human assessment and planning record. Values are advisory records and cannot execute migration." action={state.data && hasPermission("sql.assessment.manage") ? <button className="button danger" disabled={saving} onClick={() => void archive()}>Archive assessment</button> : undefined} /><div ref={outcome} tabIndex={-1}><StatusMessage message={error} error /><StatusMessage message={message} /></div>
    <LoadState loading={state.loading} error={state.error} onRetry={state.reload}>{state.data && <><section className="panel assessment-summary"><h2>Current status</h2><p><Badge value={state.data.assessmentStatus} /> <Badge value={state.data.readinessStatus} /></p><p>Target: <Link href={targetHref}>{state.data.target.name}</Link> ({state.data.targetType})</p><small>Last updated {new Date(state.data.updatedAt).toLocaleString("en-GB")} by {state.data.updatedBy}</small></section>
      <div className="assessment-grid"><section className="panel section-panel"><h2>Evidence and readiness</h2>{hasPermission("sql.assessment.manage") ? <form onSubmit={event => void save(event, "evidence")} noValidate><div className="form-grid"><Field label="Assessment status"><select value={evidence.assessmentStatus} onChange={event => setEvidence({ ...evidence, assessmentStatus: event.target.value })}>{assessmentStatuses.map(value => <option key={value}>{value}</option>)}</select></Field><Field label="Readiness"><select value={evidence.readinessStatus} onChange={event => setEvidence({ ...evidence, readinessStatus: event.target.value })}>{readinessStatuses.map(value => <option key={value}>{value}</option>)}</select></Field><Field label="Blockers" wide><textarea maxLength={4000} value={evidence.blockers} onChange={event => setEvidence({ ...evidence, blockers: event.target.value })} /></Field><Field label="Findings" wide><textarea maxLength={8000} value={evidence.findings} onChange={event => setEvidence({ ...evidence, findings: event.target.value })} /></Field><Field label="Notes" wide><textarea maxLength={4000} value={evidence.notes} onChange={event => setEvidence({ ...evidence, notes: event.target.value })} /></Field><Field label="Assessed at (local time)" wide><input type="datetime-local" value={evidence.assessedAt} onChange={event => setEvidence({ ...evidence, assessedAt: event.target.value })} /></Field></div><div className="form-actions"><button className="button primary" disabled={saving}>{saving ? "Saving…" : "Save evidence"}</button></div></form> : <div className="read-only-values"><p><strong>Blockers</strong>{state.data.blockers || "None recorded"}</p><p><strong>Findings</strong>{state.data.findings || "None recorded"}</p><p><strong>Notes</strong>{state.data.notes || "None recorded"}</p></div>}</section>
      <section className="panel section-panel"><h2>Human planning values</h2>{hasPermission("sql.assessment.plan") ? <form onSubmit={event => void save(event, "planning")} noValidate><div className="form-grid"><Field label="Target platform" wide><select value={planning.targetPlatform} onChange={event => setPlanning({ ...planning, targetPlatform: event.target.value, targetSqlVersion: event.target.value === "SqlServerOnAzureVm" ? planning.targetSqlVersion : "" })}>{platforms.map(value => <option key={value} value={value}>{value || "Not selected"}</option>)}</select></Field><Field label="Target SQL version" wide><input maxLength={100} disabled={planning.targetPlatform !== "SqlServerOnAzureVm"} value={planning.targetSqlVersion} onChange={event => setPlanning({ ...planning, targetSqlVersion: event.target.value })} /></Field><Field label="Migration approach" wide><select value={planning.migrationApproach} onChange={event => setPlanning({ ...planning, migrationApproach: event.target.value })}>{approaches.map(value => <option key={value} value={value}>{value || "Not selected"}</option>)}</select></Field></div><p className="import-notice"><strong>Planning only</strong><span>These human-selected values do not provision Azure or execute a migration.</span></p><div className="form-actions"><button className="button primary" disabled={saving}>{saving ? "Saving…" : "Save planning values"}</button></div></form> : <div className="read-only-values"><p><strong>Target platform</strong>{state.data.targetPlatform ?? "Not selected"}</p><p><strong>Target SQL version</strong>{state.data.targetSqlVersion ?? "Not selected"}</p><p><strong>Migration approach</strong>{state.data.migrationApproach ?? "Not selected"}</p></div>}</section></div></>}</LoadState>
  </>;
}

function validateEvidence(evidence: { assessmentStatus: string; readinessStatus: string; blockers: string; notes: string; assessedAt: string }, planning: { targetPlatform: string }) {
  if (evidence.assessmentStatus === "NotStarted" && (evidence.readinessStatus !== "NotAssessed" || evidence.assessedAt || planning.targetPlatform)) return "Not Started requires Not Assessed, no assessed time and no planning target.";
  if (evidence.assessmentStatus === "InProgress" && evidence.readinessStatus === "Ready") return "An in-progress assessment cannot be Ready.";
  if (evidence.assessmentStatus === "Blocked" && (evidence.readinessStatus !== "Blocked" || !evidence.blockers.trim())) return "Blocked status requires Blocked readiness and a blocker.";
  if (evidence.assessmentStatus === "Complete" && (!evidence.assessedAt || !planning.targetPlatform || evidence.readinessStatus === "NotAssessed")) return "Complete requires an assessed time, a planning target and assessed readiness.";
  if (evidence.readinessStatus === "ReadyWithConditions" && !evidence.blockers.trim() && !evidence.notes.trim()) return "Ready With Conditions requires a blocker or note.";
  if (evidence.readinessStatus === "Ready" && evidence.blockers.trim()) return "Ready requires blockers to be blank.";
  if (evidence.assessedAt && new Date(evidence.assessedAt).getTime() > Date.now() + 5 * 60_000) return "Assessed time cannot be more than five minutes in the future.";
  return "";
}

function validatePlanning(assessmentStatus: string, planning: { targetPlatform: string; targetSqlVersion: string; migrationApproach: string }) {
  if (assessmentStatus === "NotStarted" && (planning.targetPlatform || planning.targetSqlVersion || planning.migrationApproach)) return "Move the assessment to In Progress before recording planning values.";
  if (!planning.targetPlatform && (planning.targetSqlVersion.trim() || planning.migrationApproach)) return "Planning details require a target platform.";
  if (["AzureSqlDatabase", "AzureSqlManagedInstance", "SqlServerOnAzureVm"].includes(planning.targetPlatform) && !["Offline", "Online", "ToBeDetermined"].includes(planning.migrationApproach)) return "An Azure target requires Offline, Online or To Be Determined approach.";
  if (["Retain", "Retire"].includes(planning.targetPlatform) && planning.migrationApproach !== "NotApplicable") return "Retain and Retire require Not Applicable approach.";
  if (planning.targetPlatform === "Investigate" && planning.migrationApproach !== "ToBeDetermined") return "Investigate requires To Be Determined approach.";
  if (planning.targetPlatform !== "SqlServerOnAzureVm" && planning.targetSqlVersion.trim()) return "Target SQL version is allowed only for SQL Server on Azure VM.";
  return "";
}
