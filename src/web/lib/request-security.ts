const testPrincipalHeader = "x-lgr-test-principal";

export function buildContentSecurityPolicy(nonce: string, environment: string | undefined): string {
  const scriptSources = ["'self'", `'nonce-${nonce}'`];
  if (environment === "development") scriptSources.push("'unsafe-eval'");

  return [
    "default-src 'self'",
    `script-src ${scriptSources.join(" ")}`,
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data:",
    "font-src 'self'",
    "connect-src 'self' https://login.microsoftonline.com",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self' https://login.microsoftonline.com",
    "frame-ancestors 'none'",
    "upgrade-insecure-requests"
  ].join("; ");
}

export function buildApiRequestHeaders(
  requestHeaders: Headers,
  environment: string | undefined,
  configuredTestPrincipal: string | undefined,
  forwardedHeaders: readonly string[],
  prohibitedHeaders: readonly string[]
): Headers {
  const headers = new Headers();
  forwardedHeaders.forEach(name => {
    const value = requestHeaders.get(name);
    if (value) headers.set(name, value);
  });
  prohibitedHeaders.forEach(name => headers.delete(name));

  if (environment === "development") {
    const alias = configuredTestPrincipal?.trim();
    if (!alias) {
      throw new Error(
        "Local development authentication is not configured. Set NEXT_PUBLIC_LGR_TEST_PRINCIPAL to an allow-listed synthetic alias and restart the frontend."
      );
    }
    headers.set(testPrincipalHeader, alias);
  }

  return headers;
}
