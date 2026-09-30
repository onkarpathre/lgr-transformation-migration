import type { Metadata } from "next";
import "./globals.css";
import { AppShell } from "@/components/AppShell";
import { ApiProvider } from "@/components/ApiContext";
import { EntraAuthGate, EntraAuthProvider } from "@/components/EntraAuth";

export const metadata: Metadata = {
  title: { default: "LGR Transformation and Migration", template: "%s | LGR Transformation and Migration" },
  description: "A single source of truth for Local Government reorganisation migration programmes."
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body><EntraAuthProvider><EntraAuthGate><ApiProvider><AppShell>{children}</AppShell></ApiProvider></EntraAuthGate></EntraAuthProvider></body>
    </html>
  );
}
