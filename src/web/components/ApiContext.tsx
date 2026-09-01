"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";

const DEMO_CUSTOMER = "11111111-1111-1111-1111-111111111111";
const DEMO_PROJECT = "22222222-2222-2222-2222-222222222222";
const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:5000";

type Named = { id: string; name: string };
type ApiContextValue = {
  customerId: string;
  projectId: string;
  customers: Named[];
  projects: Named[];
  setCustomerId: (id: string) => void;
  setProjectId: (id: string) => void;
  api: <T>(path: string, init?: RequestInit) => Promise<T>;
};

const Context = createContext<ApiContextValue | null>(null);

export function ApiProvider({ children }: { children: React.ReactNode }) {
  const [customerId, setCustomer] = useState(DEMO_CUSTOMER);
  const [projectId, setProject] = useState(DEMO_PROJECT);
  const [customers, setCustomers] = useState<Named[]>([{ id: DEMO_CUSTOMER, name: "Demo Council" }]);
  const [projects, setProjects] = useState<Named[]>([{ id: DEMO_PROJECT, name: "LGR Azure Transformation Programme" }]);

  useEffect(() => {
    setCustomer(localStorage.getItem("lgr-customer") ?? DEMO_CUSTOMER);
    setProject(localStorage.getItem("lgr-project") ?? DEMO_PROJECT);
  }, []);

  const api = useCallback(async <T,>(path: string, init: RequestInit = {}): Promise<T> => {
    const headers = new Headers(init.headers);
    headers.set("X-Customer-Id", customerId);
    headers.set("X-Project-Id", projectId);
    headers.set("X-User-Name", "poc.web@demo-council.example");
    if (!(init.body instanceof FormData)) headers.set("Content-Type", "application/json");
    const response = await fetch(`${API_BASE}${path}`, {
      ...init,
      headers
    });
    if (!response.ok) {
      const problem = await response.json().catch(() => null) as { detail?: string; title?: string } | null;
      throw new Error(problem?.detail ?? problem?.title ?? `Request failed (${response.status})`);
    }
    if (response.status === 204) return undefined as T;
    return response.json() as Promise<T>;
  }, [customerId, projectId]);

  useEffect(() => {
    Promise.all([
      api<Array<{ id: string; name: string }>>("/api/customers"),
      api<Array<{ id: string; name: string }>>("/api/projects")
    ]).then(([customerData, projectData]) => {
      setCustomers(customerData);
      setProjects(projectData);
    }).catch(() => { /* Keep usable development defaults while the API starts. */ });
  }, [api]);

  const setCustomerId = (id: string) => { localStorage.setItem("lgr-customer", id); setCustomer(id); };
  const setProjectId = (id: string) => { localStorage.setItem("lgr-project", id); setProject(id); };
  const value = useMemo(() => ({ customerId, projectId, customers, projects, setCustomerId, setProjectId, api }), [customerId, projectId, customers, projects, api]);
  return <Context.Provider value={value}>{children}</Context.Provider>;
}

export function useApi() {
  const context = useContext(Context);
  if (!context) throw new Error("useApi must be used inside ApiProvider");
  return context;
}
