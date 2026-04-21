import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { loginOpenAICodex, refreshOpenAICodexToken } from "@mariozechner/pi-ai/oauth";
import { streamSimpleOpenAICodexResponses } from "@mariozechner/pi-ai/openai-codex-responses";

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
