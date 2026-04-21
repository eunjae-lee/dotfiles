import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { existsSync, realpathSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { pathToFileURL } from "node:url";

function findPiAiDistDir() {
  const rawCandidates = [process.argv[1], process.env.npm_execpath, process.execPath].filter(
    (value): value is string => Boolean(value),
  );
  const candidates = Array.from(
    new Set(
      rawCandidates.flatMap((candidate) => {
        try {
          return [candidate, realpathSync(candidate)];
        } catch {
          return [candidate];
        }
      }),
    ),
  );

  for (const candidate of candidates) {
    try {
      const packageRootCandidates = [
        resolve(dirname(candidate), ".."),
        resolve(dirname(candidate), "../.."),
        resolve(dirname(candidate), "../../.."),
      ];

      for (const packageRoot of packageRootCandidates) {
        const piAiDistDir = resolve(packageRoot, "node_modules/@mariozechner/pi-ai/dist");
        if (existsSync(resolve(piAiDistDir, "oauth.js"))) {
          return piAiDistDir;
        }
      }
    } catch {
      // Try the next candidate.
    }
  }

  throw new Error("Could not locate bundled @mariozechner/pi-ai files from the running pi installation");
}

const piAiDistDir = findPiAiDistDir();

const { loginOpenAICodex, refreshOpenAICodexToken } = await import(pathToFileURL(resolve(piAiDistDir, "oauth.js")).href);
const { streamSimpleOpenAICodexResponses } = await import(
  pathToFileURL(resolve(piAiDistDir, "providers/openai-codex-responses.js")).href,
);

export default function (pi: ExtensionAPI) {
  pi.registerProvider("openai2", {
    baseUrl: "https://chatgpt.com/backend-api",
    api: "openai-codex-responses",
    models: [
      {
        id: "gpt-5.1",
        name: "GPT-5.1",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 1.25, output: 10, cacheRead: 0.125, cacheWrite: 0 },
        contextWindow: 272000,
        maxTokens: 128000,
      },
      {
        id: "gpt-5.1-codex-max",
        name: "GPT-5.1 Codex Max",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 1.25, output: 10, cacheRead: 0.125, cacheWrite: 0 },
        contextWindow: 272000,
        maxTokens: 128000,
      },
      {
        id: "gpt-5.1-codex-mini",
        name: "GPT-5.1 Codex Mini",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 0.25, output: 2, cacheRead: 0.025, cacheWrite: 0 },
        contextWindow: 272000,
        maxTokens: 128000,
      },
      {
        id: "gpt-5.2",
        name: "GPT-5.2",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 1.75, output: 14, cacheRead: 0.175, cacheWrite: 0 },
        contextWindow: 272000,
        maxTokens: 128000,
      },
      {
        id: "gpt-5.2-codex",
        name: "GPT-5.2 Codex",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 1.75, output: 14, cacheRead: 0.175, cacheWrite: 0 },
        contextWindow: 272000,
        maxTokens: 128000,
      },
      {
        id: "gpt-5.3-codex",
        name: "GPT-5.3 Codex",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 1.75, output: 14, cacheRead: 0.175, cacheWrite: 0 },
        contextWindow: 272000,
        maxTokens: 128000,
      },
      {
        id: "gpt-5.3-codex-spark",
        name: "GPT-5.3 Codex Spark",
        reasoning: true,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 128000,
      },
      {
        id: "gpt-5.4",
        name: "GPT-5.4",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 2.5, output: 15, cacheRead: 0.25, cacheWrite: 0 },
        contextWindow: 272000,
        maxTokens: 128000,
      },
    ],
    oauth: {
      name: "ChatGPT Plus/Pro (Codex Subscription) 2",
      async login(callbacks) {
        return loginOpenAICodex({
          onAuth: callbacks.onAuth,
          onPrompt: callbacks.onPrompt,
          onProgress: callbacks.onProgress,
          onManualCodeInput: callbacks.onManualCodeInput,
          originator: "pi",
        });
      },
      async refreshToken(credentials) {
        return refreshOpenAICodexToken(credentials.refresh);
      },
      getApiKey(credentials) {
        return credentials.access;
      },
    },
    streamSimple: streamSimpleOpenAICodexResponses,
  });
}
