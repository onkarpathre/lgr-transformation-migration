import { rmSync } from "node:fs";
import { resolve } from "node:path";

const buildDirectory = resolve(".next");
rmSync(buildDirectory, { recursive: true, force: true });
console.log("Removed prior Next.js output before the AzureDemo production build.");
