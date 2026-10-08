import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { buildApiRequestHeaders, buildContentSecurityPolicy } from "@/lib/request-security";

const source = (path: string) => readFileSync(resolve(process.cwd(), path), "utf8");
const forwardedHeaders = ["authorization", "x-project-id", "content-type"];
const prohibitedHeaders = ["x-lgr-test-principal"];

describe("Azure demo deployment contracts", () => {
  it("uses MTP production metadata and does not expose internal authentication details", () => {
    const layout = source("app/layout.tsx");
    const shell = source("components/AppShell.tsx");
    const productionPresentation = `${layout}\n${shell}`;

    expect(layout).toContain("MTP – Transformation & Migration Platform");
    expect(layout).not.toContain("LGR Transformation and Migration");
    expect(shell).toContain("Restricted synthetic non-production management demo");
    expect(productionPresentation).not.toMatch(/LocalTest|X-Lgr-Test-Principal|NEXT_PUBLIC_LGR_TEST_PRINCIPAL/);
  });

  it("uses a narrow same-origin proxy and strips caller identity authority", () => {
    const proxy = source("app/api/[...path]/route.ts");
    expect(proxy).toContain("allowedRoots");
    expect(proxy).toContain("API_ORIGIN");
    expect(proxy).toContain("x-lgr-test-principal");
    expect(proxy).toContain("x-project-id");
    expect(proxy).not.toContain("NEXT_PUBLIC_API_BASE_URL");
  });

  it("uses PKCE and keeps access tokens out of persistent browser storage", () => {
    const auth = source("components/EntraAuth.tsx");
    expect(auth).toContain('code_challenge_method: "S256"');
    expect(auth).toContain("crypto.subtle.digest");
    expect(auth).not.toMatch(/localStorage/);
    expect(auth).not.toMatch(/setItem\([^,]+,\s*result\.access_token/);
  });

  it("exposes web readiness and required security-header policy", () => {
    expect(source("app/health/route.ts")).toContain("/health/ready");
    const middleware = source("proxy.ts");
    for (const header of ["Strict-Transport-Security", "Content-Security-Policy", "X-Content-Type-Options", "Referrer-Policy", "Permissions-Policy", "X-Frame-Options"]) expect(middleware).toContain(header);
  });

  it("allows eval only in the development Content Security Policy", () => {
    const development = buildContentSecurityPolicy("development-nonce", "development");
    const production = buildContentSecurityPolicy("production-nonce", "production");
    const test = buildContentSecurityPolicy("test-nonce", "test");

    expect(development).toContain("script-src 'self' 'nonce-development-nonce' 'unsafe-eval'");
    expect(production).toContain("script-src 'self' 'nonce-production-nonce'");
    expect(production).not.toContain("'unsafe-eval'");
    expect(test).not.toContain("'unsafe-eval'");
  });

  it("suppresses caller-supplied LocalTest identity in production", () => {
    const requestHeaders = new Headers({
      "Authorization": "Bearer token",
      "X-Lgr-Test-Principal": "caller-controlled"
    });

    const headers = buildApiRequestHeaders(requestHeaders, "production", "manager-project-a", forwardedHeaders, prohibitedHeaders);

    expect(headers.get("Authorization")).toBe("Bearer token");
    expect(headers.has("X-Lgr-Test-Principal")).toBe(false);
  });

  it("requires an explicitly configured synthetic alias in development", () => {
    expect(() => buildApiRequestHeaders(new Headers(), "development", undefined, forwardedHeaders, prohibitedHeaders)).toThrow(/NEXT_PUBLIC_LGR_TEST_PRINCIPAL/);
    expect(() => buildApiRequestHeaders(new Headers(), "development", "   ", forwardedHeaders, prohibitedHeaders)).toThrow(/NEXT_PUBLIC_LGR_TEST_PRINCIPAL/);

    const headers = buildApiRequestHeaders(
      new Headers({ "X-Lgr-Test-Principal": "caller-controlled" }),
      "development",
      " manager-project-a ",
      forwardedHeaders,
      prohibitedHeaders
    );
    expect(headers.get("X-Lgr-Test-Principal")).toBe("manager-project-a");
  });
});
