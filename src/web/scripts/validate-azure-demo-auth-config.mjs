import { fileURLToPath } from "node:url";
import { resolve } from "node:path";

const GUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/iu;
const SCOPE_PATTERN = /^api:\/\/([0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12})\/lgr\.access$/u;
const REQUIRED_SETTINGS = [
  "NEXT_PUBLIC_ENTRA_TENANT_ID",
  "NEXT_PUBLIC_ENTRA_CLIENT_ID",
  "NEXT_PUBLIC_API_SCOPE",
  "AZDEMO_API_CLIENT_ID"
];
const UNRESOLVED_EXPRESSIONS = [
  { pattern: /\$\([^\r\n)]*\)/u, name: "Azure Pipelines macro" },
  { pattern: /\$\{\{[\s\S]*?\}\}/u, name: "Azure Pipelines template expression" },
  { pattern: /\$\[[\s\S]*?\]/u, name: "Azure Pipelines runtime expression" }
];

export class AzureDemoAuthConfigurationError extends Error {
  constructor(setting, reason) {
    super(`AzureDemo authentication configuration invalid: ${setting} ${reason}.`);
    this.name = "AzureDemoAuthConfigurationError";
  }
}

function invalid(setting, reason) {
  throw new AzureDemoAuthConfigurationError(setting, reason);
}

function requireSetting(environment, setting) {
  const value = environment[setting];
  if (typeof value !== "string" || value.length === 0) {
    invalid(setting, "is missing or empty");
  }
  if (/^\s+$/u.test(value)) {
    invalid(setting, "is blank or whitespace-only");
  }
  for (const expression of UNRESOLVED_EXPRESSIONS) {
    if (expression.pattern.test(value)) {
      invalid(setting, `contains an unresolved ${expression.name}`);
    }
  }
  return value;
}

function isObviousPlaceholderGuid(value) {
  return /^([0-9a-f])\1{31}$/iu.test(value.replaceAll("-", ""));
}

function validateGuid(setting, value) {
  if (/\s/u.test(value)) {
    invalid(setting, "must not contain leading, trailing, or embedded whitespace");
  }
  if (!GUID_PATTERN.test(value)) {
    invalid(setting, "must be a GUID in 8-4-4-4-12 hexadecimal form");
  }
  if (isObviousPlaceholderGuid(value)) {
    invalid(setting, "must not be an obvious repeated-digit placeholder GUID, including the all-zero GUID");
  }
}

export function validateAzureDemoAuthConfig(environment = process.env) {
  const values = Object.fromEntries(
    REQUIRED_SETTINGS.map(setting => [setting, requireSetting(environment, setting)])
  );

  validateGuid("NEXT_PUBLIC_ENTRA_TENANT_ID", values.NEXT_PUBLIC_ENTRA_TENANT_ID);
  validateGuid("NEXT_PUBLIC_ENTRA_CLIENT_ID", values.NEXT_PUBLIC_ENTRA_CLIENT_ID);
  validateGuid("AZDEMO_API_CLIENT_ID", values.AZDEMO_API_CLIENT_ID);

  const scopeMatch = SCOPE_PATTERN.exec(values.NEXT_PUBLIC_API_SCOPE);
  if (!scopeMatch) {
    invalid(
      "NEXT_PUBLIC_API_SCOPE",
      "must be exactly one delegated scope in the form api://<AZDEMO_API_CLIENT_ID>/lgr.access, with no whitespace, query, fragment, or additional scopes"
    );
  }
  if (isObviousPlaceholderGuid(scopeMatch[1])) {
    invalid("NEXT_PUBLIC_API_SCOPE", "must not contain an obvious repeated-digit placeholder API client GUID");
  }
  if (scopeMatch[1].toLowerCase() !== values.AZDEMO_API_CLIENT_ID.toLowerCase()) {
    invalid("NEXT_PUBLIC_API_SCOPE", "contains an API client GUID that does not match AZDEMO_API_CLIENT_ID");
  }

  return true;
}

const invokedPath = process.argv[1] ? resolve(process.argv[1]) : "";
if (invokedPath === fileURLToPath(import.meta.url)) {
  try {
    validateAzureDemoAuthConfig();
    console.log("AzureDemo authentication configuration passed syntactic build validation.");
  } catch (error) {
    console.error(error instanceof Error ? error.message : "AzureDemo authentication configuration validation failed.");
    process.exitCode = 1;
  }
}
