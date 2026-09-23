"use client";

import Link from "next/link";
import { FormEvent, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { ApiError, useApi } from "@/components/ApiContext";
import { Field, LoadState, PageHeader, StatusMessage, useData } from "@/components/ui";
import { Application, Dependency, DependencyReference, Paged, Server, SqlDatabase, SqlInstance } from "@/types/api";

type EndpointOption = { value: string; label: string };
const dependencyTypes = ["Service", "DataRead", "DataWrite", "ApiCall", "FileTransfer", "Authentication", "NetworkConnectivity", "OperationalSequence"];

export default function NewDependencyPage() {
  const router = useRouter();
  const { api, hasPermission } = useApi();
  const applications = useData<Paged<Application>>("/api/applications?pageSize=200");
  const servers = useData<Paged<Server>>("/api/servers?pageSize=200");
  const instances = useData<Paged<SqlInstance>>("/api/v1/sql-instances?pageSize=200");
  const databases = useData<Paged<SqlDatabase>>("/api/v1/sql-databases?pageSize=200");
  const references = useData<Paged<DependencyReference>>("/api/v1/dependency-references?pageSize=200");
  const [source, setSource] = useState(""); const [target, setTarget] = useState("");
  const [dependencyType, setDependencyType] = useState("Service"); const [criticality, setCriticality] = useState("Mandatory");
  const [description, setDescription] = useState(""); const [businessContext, setBusinessContext] = useState("");
  const [saving, setSaving] = useState(false); const [error, setError] = useState("");
  const [referenceName, setReferenceName] = useState(""); const [referenceType, setReferenceType] = useState("ExternalSystem");
  const errorSummary = useRef<HTMLDivElement>(null);
  const canManage = hasPermission("dependency.manage");
  const loading = applications.loading || servers.loading || instances.loading || databases.loading || references.loading;
  const loadError = applications.error || servers.error || instances.error || databases.error || references.error;
  const sourceOptions = useMemo<EndpointOption[]>(() => [
    ...(applications.data?.items ?? []).map(item => ({ value: `Application:${item.id}`, label: `Application · ${item.name}` })),
    ...(servers.data?.items ?? []).map(item => ({ value: `Server:${item.id}`, label: `Server · ${item.hostname}` })),
    ...(instances.data?.items ?? []).map(item => ({ value: `SqlInstance:${item.id}`, label: `SQL instance · ${item.instanceName}` })),
    ...(databases.data?.items ?? []).map(item => ({ value: `SqlDatabase:${item.id}`, label: `SQL database · ${item.name}` }))
  ], [applications.data, servers.data, instances.data, databases.data]);
  const targetOptions = useMemo<EndpointOption[]>(() => [
    ...sourceOptions,
    ...(references.data?.items ?? []).map(item => ({ value: `DependencyReference:${item.id}`, label: `${item.referenceType} reference · ${item.name} · ${item.resolutionStatus}` }))
  ], [sourceOptions, references.data]);

  const endpoint = (value: string) => { const [type, id] = value.split(":"); return { type, id }; };
  const submit = async (event: FormEvent) => {
    event.preventDefault(); setSaving(true); setError("");
    try {
      if (!source || !target) throw new Error("Choose both a dependent source and a provider target.");
      const created = await api<Dependency>("/api/v1/dependencies", { method: "POST", body: JSON.stringify({ source: endpoint(source), target: endpoint(target), dependencyType, criticality, description, businessContext }) });
      router.push(`/planning/dependencies/${created.id}`);
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : "Unable to create dependency");
      requestAnimationFrame(() => errorSummary.current?.focus());
    } finally { setSaving(false); }
  };
  const createReference = async () => {
    setSaving(true); setError("");
    try {
      const created = await api<DependencyReference>("/api/v1/dependency-references", { method: "POST", body: JSON.stringify({ referenceType, name: referenceName, description: "", resolutionStatus: "Unresolved" }) });
      await references.reload(); setTarget(`DependencyReference:${created.id}`); setReferenceName("");
    } catch (caught) {
      const message = caught instanceof ApiError ? caught.message : "Unable to create reference"; setError(message); requestAnimationFrame(() => errorSummary.current?.focus());
    } finally { setSaving(false); }
  };

  if (!canManage) return <><PageHeader eyebrow="Planning / Dependencies" title="Add dependency" description="Dependency management permission is required." /><StatusMessage message="You have read-only access to the dependency register." error /></>;
  return <>
    <PageHeader eyebrow="Planning / Dependencies / New" title="Add dependency" description="Record a directed source-depends-on-target planning assertion. Endpoints cannot be changed after creation." />
    <LoadState loading={loading} error={loadError}>
      <form className="panel form-grid" onSubmit={submit}>
        <div ref={errorSummary} tabIndex={-1} className="wide"><StatusMessage message={error} error /></div>
        <Field label="Dependent source"><select required value={source} onChange={event => setSource(event.target.value)}><option value="">Choose source</option>{sourceOptions.map(option => <option key={option.value} value={option.value}>{option.label}</option>)}</select></Field>
        <Field label="Provider target"><select required value={target} onChange={event => setTarget(event.target.value)}><option value="">Choose target</option>{targetOptions.map(option => <option key={option.value} value={option.value}>{option.label}</option>)}</select></Field>
        <Field label="Dependency type"><select value={dependencyType} onChange={event => setDependencyType(event.target.value)}>{dependencyTypes.map(value => <option key={value}>{value}</option>)}</select></Field>
        <Field label="Criticality"><select value={criticality} onChange={event => setCriticality(event.target.value)}><option>Mandatory</option><option>Advisory</option></select></Field>
        <Field label="Description" wide><textarea maxLength={2000} value={description} onChange={event => setDescription(event.target.value)} /></Field>
        <Field label="Business context" wide><textarea maxLength={4000} value={businessContext} onChange={event => setBusinessContext(event.target.value)} /></Field>
        <div className="form-actions wide"><Link className="button secondary" href="/planning/dependencies">Cancel</Link><button className="button primary" disabled={saving}>{saving ? "Saving…" : "Create dependency"}</button></div>
      </form>
      <section className="panel"><h2>Create an inert named target</h2><p>Use this only when the target is not yet canonical inventory. The label is never opened, called, mounted or probed.</p><div className="form-grid"><Field label="Reference type"><select value={referenceType} onChange={event => setReferenceType(event.target.value)}><option>FileShare</option><option>Api</option><option>ExternalSystem</option></select></Field><Field label="Reference name"><input maxLength={200} value={referenceName} onChange={event => setReferenceName(event.target.value)} /></Field><div className="form-actions wide"><button type="button" className="button secondary" disabled={saving || !referenceName.trim()} onClick={createReference}>Create unresolved reference</button></div></div></section>
    </LoadState>
  </>;
}
