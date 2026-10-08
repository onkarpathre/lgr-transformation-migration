import type { Metadata } from "next";
import { connection } from "next/server";
import "./globals.css";
import { AppShell } from "@/components/AppShell";
import { ApiProvider } from "@/components/ApiContext";
import { EntraAuthGate, EntraAuthProvider } from "@/components/EntraAuth";

export const metadata: Metadata = {
  title: { default: "MTP – Transformation & Migration Platform", template: "%s | MTP – Transformation & Migration Platform" },
  description: "A governed transformation and migration planning platform for restricted management demonstrations."
};

export default async function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  await connection();

  return (
    <html lang="en">
      <body><EntraAuthProvider><EntraAuthGate><ApiProvider><AppShell>{children}</AppShell></ApiProvider></EntraAuthGate></EntraAuthProvider></body>
    </html>
  );
}
