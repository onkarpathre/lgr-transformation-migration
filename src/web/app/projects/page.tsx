"use client";

import { useState } from "react";
import { useApi } from "@/components/ApiContext";
import { Badge, Field, FieldError, FormActions, LoadState, Modal, PageHeader, formatDate, useData, useSubmit } from "@/components/ui";
import { Project } from "@/types/api";

const blank: Project = { id: "", name: "", description: "", status: "Active", plannedStartDate: "", plannedEndDate: "" };

export default function ProjectsPage() {
  const { api } = useApi(); const { data, loading, error, reload } = useData<Project[]>("/api/projects");
  const [editing, setEditing] = useState<Project | null>(null); const { saving, formError, submit } = useSubmit(() => { setEditing(null); void reload(); });
  const save = (project: Project) => api(project.id ? `/api/projects/${project.id}` : "/api/projects", { method: project.id ? "PUT" : "POST", body: JSON.stringify(project) });
  return <><PageHeader eyebrow="Administration" title="Projects" description="Transformation programmes within the selected customer." action={<button className="button primary" onClick={() => setEditing(blank)}>New project</button>} />
    <LoadState loading={loading} error={error}><div className="card-grid">{data?.map(project => <article className="project-card" key={project.id}><div className="project-card-top"><Badge value={project.status} /><button className="text-button" onClick={() => setEditing(project)}>Edit</button></div><h2>{project.name}</h2><p>{project.description}</p><div className="date-range"><span><small>Planned start</small><strong>{formatDate(project.plannedStartDate)}</strong></span><span><small>Planned end</small><strong>{formatDate(project.plannedEndDate)}</strong></span></div></article>)}</div></LoadState>
    {editing && <Modal title={editing.id ? "Edit project" : "Create project"} onClose={() => setEditing(null)}><form onSubmit={e => submit(e, () => save(editing))}><div className="form-grid"><Field label="Project name" wide><input required value={editing.name} onChange={e => setEditing({ ...editing, name: e.target.value })} /></Field><Field label="Description" wide><textarea value={editing.description} onChange={e => setEditing({ ...editing, description: e.target.value })} /></Field><Field label="Status"><select value={editing.status} onChange={e => setEditing({ ...editing, status: e.target.value })}><option>Active</option><option>Planning</option><option>Completed</option></select></Field><Field label="Planned start"><input type="date" value={editing.plannedStartDate ?? ""} onChange={e => setEditing({ ...editing, plannedStartDate: e.target.value })} /></Field><Field label="Planned end"><input type="date" value={editing.plannedEndDate ?? ""} onChange={e => setEditing({ ...editing, plannedEndDate: e.target.value })} /></Field></div><FieldError value={formError} /><FormActions saving={saving} onCancel={() => setEditing(null)} /></form></Modal>}
  </>;
}
