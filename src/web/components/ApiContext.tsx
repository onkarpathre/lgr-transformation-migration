"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";

const DEMO_CUSTOMER = "11111111-1111-1111-1111-111111111111";
const DEMO_PROJECT = "22222222-2222-2222-2222-222222222222";
const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:5000";
const TEST_PRINCIPAL_HEADER = "X-Lgr-Test-Principal";

function getDevelopmentTestPrincipal(): string | null {
  if (process.env.NODE_ENV !== "development") return null;

  const principal = process.env.NEXT_PUBLIC_LGR_TEST_PRINCIPAL?.trim();
  if (!principal) {
    throw new Error(
      "Local development authentication is not configured. Set NEXT_PUBLIC_LGR_TEST_PRINCIPAL to an allow-listed synthetic alias and restart the frontend."
    );
  }

  return principal;
}

const DEVELOPMENT_TEST_PRINCIPAL = getDevelopmentTestPrincipal();

type Named = { id: string; name: string };
export type ApiProblem = { title?: string; detail?: string; errorCode?: string; correlationId?: string; errors?: Record<string, string[]> };
export class ApiError extends Error {
  constructor(message: string, public readonly status: number, public readonly errorCode = "request_failed", public readonly correlationId = "", public readonly fieldErrors: Record<string, string[]> = {}) { super(message); }
}
export type ApiResponse<T> = { data: T; etag: string | null };
type ApiContextValue = {
  customerId: string;
  projectId: string;
  customers: Named[];
  projects: Named[];
  setCustomerId: (id: string) => void;
  setProjectId: (id: string) => void;
  api: <T>(path: string, init?: RequestInit) => Promise<T>;
  apiResponse: <T>(path: string, init?: RequestInit) => Promise<ApiResponse<T>>;
  permissions: ReadonlySet<string>;
  capabilitiesLoading: boolean;
  hasPermission: (permission: string) => boolean;
};

const Context = createContext<ApiContextValue | null>(null);

export function ApiProvider({ children }: { children: React.ReactNode }) {
  const [customerId, setCustomer] = useState(DEMO_CUSTOMER);
  const [projectId, setProject] = useState(DEMO_PROJECT);
  const [customers, setCustomers] = useState<Named[]>([{ id: DEMO_CUSTOMER, name: "Demo Council" }]);
  const [projects, setProjects] = useState<Named[]>([{ id: DEMO_PROJECT, name: "LGR Azure Transformation Programme" }]);
  const [permissions, setPermissions] = useState<ReadonlySet<string>>(new Set());
  const [capabilitiesLoading, setCapabilitiesLoading] = useState(true);

  const apiResponse = useCallback(async <T,>(path: string, init: RequestInit = {}): Promise<ApiResponse<T>> => {
    const headers = new Headers(init.headers);
    headers.delete(TEST_PRINCIPAL_HEADER);
    if (DEVELOPMENT_TEST_PRINCIPAL) {
      headers.set(TEST_PRINCIPAL_HEADER, DEVELOPMENT_TEST_PRINCIPAL);
    }
    headers.set("X-Project-Id", projectId);
    if (!(init.body instanceof FormData)) headers.set("Content-Type", "application/json");
    const response = await fetch(`${API_BASE}${path}`, {
      ...init,
      headers,
      cache: "no-store"
    });
    if (!response.ok) {
      const problem = await response.json().catch(() => null) as ApiProblem | null;
      throw new ApiError(problem?.detail ?? problem?.title ?? `Request failed (${response.status})`, response.status, problem?.errorCode, problem?.correlationId, problem?.errors);
    }
    const data = response.status === 204 ? undefined as T : await response.json() as T;
    return { data, etag: response.headers.get("ETag") };
  }, [projectId]);

  const api = useCallback(async <T,>(path: string, init: RequestInit = {}): Promise<T> => (await apiResponse<T>(path, init)).data, [apiResponse]);

  useEffect(() => {
    Promise.all([
      api<Array<{ id: string; name: string }>>("/api/customers"),
      api<Array<{ id: string; name: string }>>("/api/projects")
    ]).then(([customerData, projectData]) => {
      setCustomers(customerData);
      setProjects(projectData);
    }).catch(() => { /* Keep usable development defaults while the API starts. */ });
  }, [api]);

  useEffect(() => {
    let active = true;
    setPermissions(new Set());
    setCapabilitiesLoading(true);
    api<{ permissions: string[] }>("/api/v1/session/capabilities")
      .then(result => { if (active) setPermissions(new Set(result.permissions)); })
      .catch(() => { if (active) setPermissions(new Set()); })
      .finally(() => { if (active) setCapabilitiesLoading(false); });
    return () => { active = false; };
  }, [api, projectId]);

  const setCustomerId = (id: string) => setCustomer(id);
  const setProjectId = (id: string) => setProject(id);
  const hasPermission = useCallback((permission: string) => permissions.has(permission), [permissions]);
  const value = useMemo(() => ({ customerId, projectId, customers, projects, setCustomerId, setProjectId, api, apiResponse, permissions, capabilitiesLoading, hasPermission }), [customerId, projectId, customers, projects, api, apiResponse, permissions, capabilitiesLoading, hasPermission]);
  return <Context.Provider value={value}>{children}</Context.Provider>;
}

export function useApi() {
  const context = useContext(Context);
  if (!context) throw new Error("useApi must be used inside ApiProvider");
  return context;
}
