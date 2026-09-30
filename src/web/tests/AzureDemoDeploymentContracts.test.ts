import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const source = (path: string) => readFileSync(resolve(process.cwd(), path), "utf8");

describe("Azure demo deployment contracts", () => {
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
});
