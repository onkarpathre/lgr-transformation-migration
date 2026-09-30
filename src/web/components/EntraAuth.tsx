"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";

type AuthState = "initializing" | "signed-out" | "authenticated" | "local" | "error";
type AuthContextValue = { accessToken: string | null; state: AuthState; error: string; login: () => Promise<void>; logout: () => void };
const tenantId = process.env.NEXT_PUBLIC_ENTRA_TENANT_ID?.trim() ?? "";
const clientId = process.env.NEXT_PUBLIC_ENTRA_CLIENT_ID?.trim() ?? "";
const apiScope = process.env.NEXT_PUBLIC_API_SCOPE?.trim() ?? "";
const configured = Boolean(tenantId && clientId && apiScope);
const required = process.env.NODE_ENV === "production";
const stateKey = "lgr.entra.state";
const verifierKey = "lgr.entra.verifier";
const Context = createContext<AuthContextValue>({ accessToken: null, state: "local", error: "", login: async () => undefined, logout: () => undefined });

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  bytes.forEach(value => { binary += String.fromCharCode(value); });
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

function randomValue(size = 32): string {
  const bytes = new Uint8Array(size);
  crypto.getRandomValues(bytes);
  return base64Url(bytes);
}

async function challenge(verifier: string): Promise<string> {
  return base64Url(new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(verifier))));
}

function redirectUri(): string { return `${window.location.origin}/`; }

export function EntraAuthProvider({ children }: { children: React.ReactNode }) {
  const [accessToken, setAccessToken] = useState<string | null>(null);
  const [state, setState] = useState<AuthState>(required ? "initializing" : "local");
  const [error, setError] = useState("");

  useEffect(() => {
    if (!required) return;
    if (!configured) { setError("Microsoft Entra sign-in is not configured for this deployment."); setState("error"); return; }
    const query = new URLSearchParams(window.location.search);
    if (query.get("error")) {
      sessionStorage.removeItem(stateKey); sessionStorage.removeItem(verifierKey);
      window.history.replaceState({}, document.title, "/");
      setError("Microsoft Entra sign-in was not completed."); setState("error"); return;
    }
    const code = query.get("code");
    if (!code) { setState("signed-out"); return; }
    const returnedState = query.get("state");
    const expectedState = sessionStorage.getItem(stateKey);
    const verifier = sessionStorage.getItem(verifierKey);
    sessionStorage.removeItem(stateKey); sessionStorage.removeItem(verifierKey);
    window.history.replaceState({}, document.title, "/");
    if (!returnedState || returnedState !== expectedState || !verifier) {
      setError("Microsoft Entra sign-in response validation failed."); setState("error"); return;
    }
    const body = new URLSearchParams({ client_id: clientId, grant_type: "authorization_code", code, redirect_uri: redirectUri(), scope: `openid profile ${apiScope}`, code_verifier: verifier });
    fetch(`https://login.microsoftonline.com/${encodeURIComponent(tenantId)}/oauth2/v2.0/token`, { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body, cache: "no-store" })
      .then(async response => { if (!response.ok) throw new Error("token_exchange_failed"); return response.json() as Promise<{ access_token?: string; expires_in?: number }>; })
      .then(result => {
        if (!result.access_token) throw new Error("token_missing");
        setAccessToken(result.access_token); setState("authenticated");
        window.setTimeout(() => { setAccessToken(null); setState("signed-out"); }, Math.max(1, (result.expires_in ?? 300) - 60) * 1000);
      })
      .catch(() => { setError("Microsoft Entra sign-in could not be completed."); setState("error"); });
  }, []);

  const login = useCallback(async () => {
    if (!configured) { setError("Microsoft Entra sign-in is not configured for this deployment."); setState("error"); return; }
    const oauthState = randomValue(); const verifier = randomValue(64);
    sessionStorage.setItem(stateKey, oauthState); sessionStorage.setItem(verifierKey, verifier);
    const query = new URLSearchParams({ client_id: clientId, response_type: "code", redirect_uri: redirectUri(), response_mode: "query", scope: `openid profile ${apiScope}`, state: oauthState, code_challenge: await challenge(verifier), code_challenge_method: "S256" });
    window.location.assign(`https://login.microsoftonline.com/${encodeURIComponent(tenantId)}/oauth2/v2.0/authorize?${query}`);
  }, []);

  const logout = useCallback(() => {
    setAccessToken(null);
    if (!required || !configured) return;
    const query = new URLSearchParams({ post_logout_redirect_uri: redirectUri() });
    window.location.assign(`https://login.microsoftonline.com/${encodeURIComponent(tenantId)}/oauth2/v2.0/logout?${query}`);
  }, []);

  const value = useMemo(() => ({ accessToken, state, error, login, logout }), [accessToken, state, error, login, logout]);
  return <Context.Provider value={value}>{children}</Context.Provider>;
}

export function EntraAuthGate({ children }: { children: React.ReactNode }) {
  const auth = useEntraAuth();
  if (!required || auth.state === "authenticated" || auth.state === "local") return children;
  return <main className="auth-gate"><section className="panel"><p className="demo-banner">Restricted synthetic non-production demo</p><h1>Sign in required</h1><p>{auth.error || "Use an assigned Agilisys workforce account to continue."}</p><button className="button primary" disabled={auth.state === "initializing"} onClick={() => void auth.login()}>{auth.state === "initializing" ? "Checking sign-in…" : "Sign in with Microsoft Entra"}</button></section></main>;
}

export function useEntraAuth() { return useContext(Context); }
