"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { useApi } from "./ApiContext";

const navigation = [
  { label: "Dashboard", href: "/", icon: "DB" },
  { label: "Customers", href: "/customers", icon: "CU" },
  { label: "Projects", href: "/projects", icon: "PR" },
  { section: "Discovery" },
  { label: "Imports", href: "/discovery/imports", icon: "DI" },
  { section: "Inventory" },
  { label: "Applications", href: "/inventory/applications", icon: "AP" },
  { label: "Servers", href: "/inventory/servers", icon: "SV" },
  { section: "Assessment" },
  { label: "Migration Decisions", href: "/assessment/migration-decisions", icon: "MD" },
  { section: "Azure Design" },
  { label: "Target Builds", href: "/azure/target-builds", icon: "AZ" },
  { label: "IP Management", href: "/azure/ip-management", icon: "IP" },
  { section: "Migration" },
  { label: "Waves", href: "/migration/waves", icon: "WV" },
  { label: "Readiness", href: "/migration/readiness", icon: "RD" },
  { label: "Runbooks", href: "/migration/runbooks", icon: "RB" },
  { section: "Administration" },
  { label: "Configuration", href: "/configuration", icon: "CF" }
] as const;

export function AppShell({ children }: { children: React.ReactNode }) {
  const path = usePathname();
  const { customerId, projectId, customers, projects, setCustomerId, setProjectId } = useApi();
  const [open, setOpen] = useState(false);
  return (
    <div className="shell">
      <aside className={`sidebar ${open ? "sidebar-open" : ""}`}>
        <div className="brand"><span className="brand-mark">LGR</span><span><strong>Transformation</strong><small>&amp; Migration</small></span></div>
        <nav aria-label="Primary navigation">
          {navigation.map((item, index) => "section" in item
            ? <p className="nav-section" key={`${item.section}-${index}`}>{item.section}</p>
            : <Link onClick={() => setOpen(false)} className={path === item.href ? "nav-link active" : "nav-link"} href={item.href} key={item.href}><span>{item.icon}</span>{item.label}</Link>)}
        </nav>
        <div className="sidebar-footer"><span className="status-dot" />Development context</div>
      </aside>
      <div className="workspace">
        <header className="topbar">
          <button className="menu-button" onClick={() => setOpen(!open)} aria-label="Toggle navigation">☰</button>
          <div className="context-controls">
            <label>Customer<select value={customerId} onChange={e => setCustomerId(e.target.value)}>{customers.map(x => <option value={x.id} key={x.id}>{x.name}</option>)}</select></label>
            <span className="context-arrow">›</span>
            <label>Project<select value={projectId} onChange={e => setProjectId(e.target.value)}>{projects.map(x => <option value={x.id} key={x.id}>{x.name}</option>)}</select></label>
          </div>
          <div className="user"><span className="user-avatar">PM</span><span><strong>Programme Manager</strong><small>Development user</small></span></div>
        </header>
        <main>{children}</main>
      </div>
    </div>
  );
}
