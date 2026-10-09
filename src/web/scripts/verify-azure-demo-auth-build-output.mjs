import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { join, resolve } from "node:path";
import { validateAzureDemoAuthConfig } from "./validate-azure-demo-auth-config.mjs";

function filesUnder(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
    const path = join(directory, entry.name);
    return entry.isDirectory() ? filesUnder(path) : [path];
  });
}

export function verifyAzureDemoAuthBuildOutput(buildDirectory = resolve(".next"), environment = process.env) {
  validateAzureDemoAuthConfig(environment);

  const staticDirectory = join(buildDirectory, "static");
  if (!existsSync(staticDirectory) || !statSync(staticDirectory).isDirectory()) {
    throw new Error("AzureDemo Next.js build output has no static client directory.");
  }

  const clientFiles = filesUnder(staticDirectory).filter(path => /\.(?:js|mjs)$/u.test(path));
  if (clientFiles.length === 0) {
    throw new Error("AzureDemo Next.js build output has no client JavaScript files.");
  }

  const clientOutput = clientFiles.map(path => readFileSync(path, "utf8"));
  for (const setting of [
    "NEXT_PUBLIC_ENTRA_TENANT_ID",
    "NEXT_PUBLIC_ENTRA_CLIENT_ID",
    "NEXT_PUBLIC_API_SCOPE"
  ]) {
    if (!clientOutput.some(content => content.includes(environment[setting]))) {
      throw new Error(`AzureDemo Next.js client output does not contain the exact validated ${setting} value.`);
    }
  }

  return true;
}

const invokedPath = process.argv[1] ? resolve(process.argv[1]) : "";
if (invokedPath === fileURLToPath(import.meta.url)) {
  try {
    verifyAzureDemoAuthBuildOutput();
    console.log("AzureDemo Next.js client output contains the exact validated public authentication configuration.");
  } catch (error) {
    console.error(error instanceof Error ? error.message : "AzureDemo Next.js client output validation failed.");
    process.exitCode = 1;
  }
}
