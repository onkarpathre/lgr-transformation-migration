import assert from "node:assert/strict";
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync, chmodSync } from "node:fs";
import { tmpdir } from "node:os";
import { delimiter, dirname, join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import {
  AzureDemoAuthConfigurationError,
  validateAzureDemoAuthConfig
} from "./validate-azure-demo-auth-config.mjs";

const valid = Object.freeze({
  NEXT_PUBLIC_ENTRA_TENANT_ID: "d68cff79-a08e-4a81-b724-e3fdea2af74d",
  NEXT_PUBLIC_ENTRA_CLIENT_ID: "9be061c9-bb94-4fdc-9347-edda6363af19",
  AZDEMO_API_CLIENT_ID: "a09f84de-7f30-4c53-86db-13b249597837",
  NEXT_PUBLIC_API_SCOPE: "api://a09f84de-7f30-4c53-86db-13b249597837/lgr.access"
});

const validatorPath = resolve("scripts/validate-azure-demo-auth-config.mjs");

function expectInvalid(configuration, setting, reason) {
  assert.throws(
    () => validateAzureDemoAuthConfig(configuration),
    error => {
      assert.ok(error instanceof AzureDemoAuthConfigurationError);
      assert.match(error.message, new RegExp(setting));
      assert.match(error.message, reason);
      return true;
    }
  );
}

test("accepts one valid synthetic tenant, SPA, API, and delegated scope configuration", () => {
  assert.equal(validateAzureDemoAuthConfig(valid), true);
});

test("rejects every required setting when missing, empty, or whitespace-only", () => {
  for (const setting of Object.keys(valid)) {
    const missing = { ...valid };
    delete missing[setting];
    expectInvalid(missing, setting, /missing or empty/);
    expectInvalid({ ...valid, [setting]: "" }, setting, /missing or empty/);
    expectInvalid({ ...valid, [setting]: " \t\r\n" }, setting, /blank or whitespace-only/);
  }
});

test("rejects the exact unresolved AzureDemo scope macro", () => {
  expectInvalid(
    { ...valid, NEXT_PUBLIC_API_SCOPE: "$(AZDEMO_API_SCOPE)" },
    "NEXT_PUBLIC_API_SCOPE",
    /unresolved Azure Pipelines macro/
  );
});

test("rejects unresolved macro, template, and runtime expressions in every other required setting", () => {
  const cases = [
    ["NEXT_PUBLIC_ENTRA_TENANT_ID", "$(AZDEMO_ENTRA_TENANT_ID)", /macro/],
    ["NEXT_PUBLIC_ENTRA_CLIENT_ID", "${{ variables.AZDEMO_SPA_CLIENT_ID }}", /template expression/],
    ["AZDEMO_API_CLIENT_ID", "$[ variables.AZDEMO_API_CLIENT_ID ]", /runtime expression/]
  ];
  for (const [setting, value, reason] of cases) {
    expectInvalid({ ...valid, [setting]: value }, setting, reason);
  }
});

test("rejects malformed and obvious placeholder GUIDs", () => {
  for (const setting of ["NEXT_PUBLIC_ENTRA_TENANT_ID", "NEXT_PUBLIC_ENTRA_CLIENT_ID", "AZDEMO_API_CLIENT_ID"]) {
    expectInvalid({ ...valid, [setting]: "not-a-guid" }, setting, /must be a GUID/);
    expectInvalid({ ...valid, [setting]: "00000000-0000-0000-0000-000000000000" }, setting, /placeholder GUID/);
    expectInvalid({ ...valid, [setting]: "ffffffff-ffff-ffff-ffff-ffffffffffff" }, setting, /placeholder GUID/);
  }
});

test("rejects wrong API identity, suffix, multiple scopes, query, fragment, and scope whitespace", () => {
  const invalidScopes = [
    ["api://3ed6407f-15dd-498b-89df-b5a6ee927e69/lgr.access", /does not match/],
    ["api://a09f84de-7f30-4c53-86db-13b249597837/user.read", /exactly one delegated scope/],
    ["api://a09f84de-7f30-4c53-86db-13b249597837/lgr.access api://a09f84de-7f30-4c53-86db-13b249597837/other", /exactly one delegated scope/],
    ["api://a09f84de-7f30-4c53-86db-13b249597837/lgr.access?x=1", /exactly one delegated scope/],
    ["api://a09f84de-7f30-4c53-86db-13b249597837/lgr.access#fragment", /exactly one delegated scope/],
    [" api://a09f84de-7f30-4c53-86db-13b249597837/lgr.access", /exactly one delegated scope/],
    ["api://a09f84de-7f30-4c53-86db-13b249597837/lgr.access\u00a0", /exactly one delegated scope/]
  ];
  for (const [scope, reason] of invalidScopes) {
    expectInvalid({ ...valid, NEXT_PUBLIC_API_SCOPE: scope }, "NEXT_PUBLIC_API_SCOPE", reason);
  }
});

test("treats GUID hexadecimal case as insignificant but scope syntax and suffix case as exact", () => {
  assert.equal(validateAzureDemoAuthConfig({
    ...valid,
    AZDEMO_API_CLIENT_ID: valid.AZDEMO_API_CLIENT_ID.toUpperCase(),
    NEXT_PUBLIC_API_SCOPE: valid.NEXT_PUBLIC_API_SCOPE.toLowerCase()
  }), true);
  expectInvalid(
    { ...valid, NEXT_PUBLIC_API_SCOPE: valid.NEXT_PUBLIC_API_SCOPE.replace("lgr.access", "LGR.ACCESS") },
    "NEXT_PUBLIC_API_SCOPE",
    /exactly one delegated scope/
  );
  expectInvalid(
    { ...valid, NEXT_PUBLIC_API_SCOPE: valid.NEXT_PUBLIC_API_SCOPE.replace("api://", "API://") },
    "NEXT_PUBLIC_API_SCOPE",
    /exactly one delegated scope/
  );
  expectInvalid(
    { ...valid, NEXT_PUBLIC_ENTRA_TENANT_ID: `${valid.NEXT_PUBLIC_ENTRA_TENANT_ID} ` },
    "NEXT_PUBLIC_ENTRA_TENANT_ID",
    /must not contain.*whitespace/
  );
});

test("CLI failures are nonzero, useful, and do not disclose rejected values", () => {
  const rejectedValue = "sensitive-looking-invalid-tenant-value";
  const result = spawnSync(process.execPath, [validatorPath], {
    cwd: process.cwd(),
    encoding: "utf8",
    env: { ...process.env, ...valid, NEXT_PUBLIC_ENTRA_TENANT_ID: rejectedValue }
  });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /NEXT_PUBLIC_ENTRA_TENANT_ID/);
  assert.match(result.stderr, /must be a GUID/);
  assert.doesNotMatch(`${result.stdout}\n${result.stderr}`, new RegExp(rejectedValue));
});

test("AzureDemo npm build entry rejects invalid configuration before next and propagates downstream failure", () => {
  const packageJson = JSON.parse(readFileSync(resolve("package.json"), "utf8"));
  assert.equal(
    packageJson.scripts["build:azure-demo"],
    "node scripts/validate-azure-demo-auth-config.mjs && next build"
  );

  const temporaryDirectory = mkdtempSync(join(tmpdir(), "azdemo-auth-build-"));
  const marker = join(temporaryDirectory, "next-reached.txt");
  const nextShim = join(temporaryDirectory, process.platform === "win32" ? "next.cmd" : "next");
  const bundledNpmCli = resolve(dirname(process.execPath), "node_modules/npm/bin/npm-cli.js");
  const npmCli = process.env.npm_execpath || (existsSync(bundledNpmCli) ? bundledNpmCli : undefined);
  const shim = process.platform === "win32"
    ? "@echo off\r\n>\"%AUTH_BUILD_MARKER%\" echo reached\r\nexit /b 29\r\n"
    : "#!/bin/sh\nprintf reached > \"$AUTH_BUILD_MARKER\"\nexit 29\n";
  writeFileSync(nextShim, shim, "utf8");
  if (process.platform !== "win32") chmodSync(nextShim, 0o755);

  try {
    const common = {
      cwd: process.cwd(),
      encoding: "utf8",
      env: {
        ...process.env,
        ...valid,
        AUTH_BUILD_MARKER: marker,
        PATH: `${temporaryDirectory}${delimiter}${process.env.PATH ?? ""}`
      }
    };
    const npmArguments = ["run", "build:azure-demo", "--silent"];
    const invokeNpm = options => npmCli
      ? spawnSync(process.execPath, [npmCli, ...npmArguments], options)
      : spawnSync("npm", npmArguments, options);
    const invalid = invokeNpm({
      ...common,
      env: { ...common.env, NEXT_PUBLIC_API_SCOPE: "$(AZDEMO_API_SCOPE)" }
    });
    assert.notEqual(invalid.status, 0);
    assert.equal(existsSync(marker), false);
    assert.match(`${invalid.stdout}\n${invalid.stderr}`, /NEXT_PUBLIC_API_SCOPE.*unresolved Azure Pipelines macro/s);

    const downstreamFailure = invokeNpm(common);
    assert.equal(existsSync(marker), true);
    assert.equal(downstreamFailure.status, 29);
  } finally {
    rmSync(temporaryDirectory, { recursive: true, force: true });
  }
});
