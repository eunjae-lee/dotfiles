import { createHash } from "node:crypto";
import { mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import path from "node:path";

export type DraftScope = "global" | "cwd";

export type DraftListItem = {
  scope: DraftScope;
  storageIndex: number;
  text: string;
};

const baseDir = path.join(homedir(), ".pi", "agent", "state", "drafts");
const cwdDir = path.join(baseDir, "cwd");
const globalFile = path.join(baseDir, "global.json");

function getCwdHash(cwd: string): string {
  return createHash("sha1").update(cwd).digest("hex").slice(0, 16);
}

function getScopeFile(scope: DraftScope, cwd: string): string {
  if (scope === "global") return globalFile;
  return path.join(cwdDir, `${getCwdHash(cwd)}.json`);
}

async function ensureDir(filePath: string): Promise<void> {
  await mkdir(path.dirname(filePath), { recursive: true });
}

async function readDraftArray(filePath: string): Promise<string[]> {
  try {
    const raw = await readFile(filePath, "utf8");
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed) || !parsed.every((item) => typeof item === "string")) {
      throw new Error(`Invalid draft store format at ${filePath}`);
    }
    return parsed;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return [];
    throw error;
  }
}

async function writeDraftArray(filePath: string, drafts: string[]): Promise<void> {
  await ensureDir(filePath);

  if (drafts.length === 0) {
    try {
      await rm(filePath);
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
    }
    return;
  }

  const tempFile = `${filePath}.tmp-${process.pid}-${Date.now()}`;
  await writeFile(tempFile, `${JSON.stringify(drafts, null, 2)}\n`, "utf8");
  await rename(tempFile, filePath);
}

export async function addDraft(scope: DraftScope, cwd: string, text: string): Promise<void> {
  const filePath = getScopeFile(scope, cwd);
  const drafts = await readDraftArray(filePath);
  drafts.push(text);
  await writeDraftArray(filePath, drafts);
}

export async function deleteDraft(scope: DraftScope, cwd: string, storageIndex: number): Promise<void> {
  const filePath = getScopeFile(scope, cwd);
  const drafts = await readDraftArray(filePath);

  if (storageIndex < 0 || storageIndex >= drafts.length) {
    throw new Error(`Draft index out of range for ${scope} drafts`);
  }

  drafts.splice(storageIndex, 1);
  await writeDraftArray(filePath, drafts);
}

export async function listDrafts(cwd: string): Promise<DraftListItem[]> {
  const [cwdDrafts, globalDrafts] = await Promise.all([
    readDraftArray(getScopeFile("cwd", cwd)),
    readDraftArray(getScopeFile("global", cwd)),
  ]);

  const cwdItems = cwdDrafts
    .map((text, storageIndex) => ({ scope: "cwd" as const, storageIndex, text }))
    .reverse();
  const globalItems = globalDrafts
    .map((text, storageIndex) => ({ scope: "global" as const, storageIndex, text }))
    .reverse();

  return [...cwdItems, ...globalItems];
}
