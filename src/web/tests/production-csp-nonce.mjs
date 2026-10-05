import assert from "node:assert/strict";

const baseUrl = process.argv[2];
assert(baseUrl, "Usage: node tests/production-csp-nonce.mjs <base-url>");

function attribute(attributes, name) {
  const match = attributes.match(new RegExp(`(?:^|\\s)${name}\\s*=\\s*(?:"([^"]*)"|'([^']*)'|([^\\s"'=<>]+))`, "i"));
  return match ? (match[1] ?? match[2] ?? match[3] ?? "") : null;
}

function isExecutableInlineScript(attributes) {
  if (attribute(attributes, "src") !== null) return false;
  const typeAttribute = attribute(attributes, "type");
  if (typeAttribute === null) return true;
  const type = typeAttribute.trim().toLowerCase();
  return type === "" || type === "module" || [
    "text/javascript",
    "application/javascript",
    "text/ecmascript",
    "application/ecmascript"
  ].includes(type);
}

async function inspectDocument(path) {
  const response = await fetch(new URL(path, baseUrl), { redirect: "manual" });
  assert.equal(response.status, 200, `${path} returned ${response.status}, expected 200.`);

  const csp = response.headers.get("content-security-policy");
  assert(csp, `${path} did not return Content-Security-Policy.`);
  const scriptSource = csp.split(";").map(value => value.trim()).find(value => value.startsWith("script-src "));
  assert(scriptSource, `${path} CSP did not contain script-src.`);
  assert(!scriptSource.includes("'unsafe-inline'"), `${path} script-src must not allow unsafe-inline.`);
  assert(!scriptSource.includes("'unsafe-eval'"), `${path} production script-src must not allow unsafe-eval.`);

  const nonceTokens = [...scriptSource.matchAll(/'nonce-([^']+)'/g)];
  assert.equal(nonceTokens.length, 1, `${path} script-src must contain exactly one nonce source.`);
  const requiredNonce = nonceTokens[0][1];

  const html = await response.text();
  const scripts = [...html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi)];
  const executableInlineScripts = scripts.filter(match => isExecutableInlineScript(match[1]));
  assert(executableInlineScripts.length > 0, `${path} did not render any executable inline scripts.`);

  for (const script of executableInlineScripts) {
    assert.equal(
      attribute(script[1], "nonce"),
      requiredNonce,
      `${path} rendered an executable inline script without the nonce required by its CSP.`
    );
  }

  return { nonce: requiredNonce, executableInlineScriptCount: executableInlineScripts.length };
}

try {
  const firstHome = await inspectDocument("/");
  const secondHome = await inspectDocument("/");
  assert.notEqual(firstHome.nonce, secondHome.nonce, "Separate document requests reused the same CSP nonce.");
  const deepRoute = await inspectDocument("/inventory/servers");

  console.log(
    `Production CSP nonce regression passed: / (${firstHome.executableInlineScriptCount}, ${secondHome.executableInlineScriptCount} inline scripts) and /inventory/servers (${deepRoute.executableInlineScriptCount} inline scripts); request nonces differ.`
  );
} catch (error) {
  console.error(error instanceof Error ? error.stack : error);
  process.exitCode = 1;
}
