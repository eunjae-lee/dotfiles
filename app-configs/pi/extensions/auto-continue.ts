import type { AgentMessage } from "@mariozechner/pi-agent-core";
import type { AssistantMessage, TextContent } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

type AutoContinueState = {
	enabled: boolean;
	prompt: string;
	maxRuns: number;
	runCount: number;
	lastAssistantText?: string;
	repeatCount: number;
};

const STATE_TYPE = "auto-continue-state";
const STATUS_KEY = "auto-continue";

const DEFAULT_STATE: AutoContinueState = {
	enabled: false,
	prompt: "",
	maxRuns: 20,
	runCount: 0,
	lastAssistantText: undefined,
	repeatCount: 0,
};

function isAssistantMessage(message: AgentMessage): message is AssistantMessage {
	return message.role === "assistant" && Array.isArray(message.content);
}

function getTextContent(message: AssistantMessage): string {
	return message.content
		.filter((block): block is TextContent => block.type === "text")
		.map((block) => block.text)
		.join("\n")
		.trim();
}

function normalizeText(text: string): string {
	return text.replace(/\s+/g, " ").trim().toLowerCase();
}

function buildAutoContinuePrompt(prompt: string): string {
	const trimmed = prompt.trim();
	const base = trimmed || "Continue from where you left off.";
	return `${base}\n\nAuto-continue instructions:\n- Continue working autonomously as far as possible.\n- Do not ask whether you should continue.\n- If you can continue, continue.\n- If you truly need user input, end your response with exactly [NEEDS_USER_INPUT] and clearly state what you need.\n- If the task is fully complete, end your response with exactly [TASK_COMPLETE].`;
}

export default function autoContinueExtension(pi: ExtensionAPI) {
	let state: AutoContinueState = { ...DEFAULT_STATE };

	function persistState() {
		pi.appendEntry(STATE_TYPE, state);
	}

	function updateStatus(ctx: ExtensionContext) {
		if (!state.enabled) {
			ctx.ui.setStatus(STATUS_KEY, undefined);
			return;
		}

		const promptLabel = state.prompt.trim() ? "" : " default";
		const label = `∞ auto-continue${promptLabel} ${state.runCount}/${state.maxRuns}`;
		ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("accent", label));
	}

	function stop(ctx: ExtensionContext, reason: string) {
		state.enabled = false;
		persistState();
		updateStatus(ctx);
		ctx.ui.notify(`Auto-continue stopped: ${reason}`, "info");
	}

	pi.registerCommand("autocontinue", {
		description: "Enable auto-continue mode with an optional stored prompt",
		handler: async (args, ctx) => {
			const prompt = args.trim() || state.prompt.trim();
			const effectivePrompt = buildAutoContinuePrompt(prompt);

			state.enabled = true;
			state.prompt = prompt;
			state.runCount = 0;
			state.lastAssistantText = undefined;
			state.repeatCount = 0;

			persistState();
			updateStatus(ctx);
			ctx.ui.notify("Auto-continue enabled", "success");

			if (ctx.isIdle()) {
				pi.sendUserMessage(effectivePrompt);
			} else {
				pi.sendUserMessage(effectivePrompt, { deliverAs: "followUp" });
				ctx.ui.notify("Initial auto-continue prompt queued", "info");
			}
		},
	});

	pi.registerCommand("autocontinue-off", {
		description: "Disable auto-continue mode",
		handler: async (_args, ctx) => {
			state.enabled = false;
			state.runCount = 0;
			state.lastAssistantText = undefined;
			state.repeatCount = 0;

			persistState();
			updateStatus(ctx);
			ctx.ui.notify("Auto-continue disabled", "info");
		},
	});

	pi.registerCommand("autocontinue-status", {
		description: "Show auto-continue status",
		handler: async (_args, ctx) => {
			if (!state.enabled) {
				ctx.ui.notify("Auto-continue: off", "info");
				return;
			}

			ctx.ui.notify(
				`Auto-continue: on (${state.runCount}/${state.maxRuns})\nPrompt: ${state.prompt || "<default>"}`,
				"info",
			);
		},
	});

	pi.on("session_start", async (_event, ctx) => {
		state = { ...DEFAULT_STATE };

		for (const entry of ctx.sessionManager.getEntries()) {
			if (entry.type === "custom" && entry.customType === STATE_TYPE && entry.data) {
				state = {
					...DEFAULT_STATE,
					...(entry.data as Partial<AutoContinueState>),
				};
			}
		}

		updateStatus(ctx);
	});

	pi.on("input", async (event) => {
		if (event.source === "interactive" || event.source === "rpc") {
			state.runCount = 0;
			state.lastAssistantText = undefined;
			state.repeatCount = 0;
			persistState();
		}
		return { action: "continue" as const };
	});

	pi.on("before_agent_start", async (event) => {
		if (!state.enabled) return;

		return {
			systemPrompt:
				event.systemPrompt +
				`\n\nAuto-continue mode is enabled.\n\nRules:\n- Do not ask the user whether you should continue.\n- If you can continue autonomously, stop naturally; the extension will resume you automatically.\n- If you truly need user input, end your response with exactly [NEEDS_USER_INPUT] and explain what you need.\n- If the task is fully complete, end your response with exactly [TASK_COMPLETE].\n- Avoid filler like "if you want, I can continue".\n- Continue with the next concrete action whenever possible.\n`,
		};
	});

	pi.on("agent_end", async (event, ctx) => {
		if (!state.enabled) return;

		const lastAssistant = [...event.messages].reverse().find((message) =>
			isAssistantMessage(message as AgentMessage),
		) as AssistantMessage | undefined;

		if (!lastAssistant) return;

		const text = getTextContent(lastAssistant);
		const normalized = normalizeText(text);
		if (!normalized) return;

		if (text.includes("[NEEDS_USER_INPUT]")) {
			stop(ctx, "waiting for your input");
			return;
		}

		if (text.includes("[TASK_COMPLETE]")) {
			stop(ctx, "task complete");
			return;
		}

		if (state.runCount >= state.maxRuns) {
			stop(ctx, `reached max runs (${state.maxRuns})`);
			return;
		}

		if (state.lastAssistantText === normalized) {
			state.repeatCount += 1;
		} else {
			state.lastAssistantText = normalized;
			state.repeatCount = 0;
		}

		if (state.repeatCount >= 2) {
			stop(ctx, "detected repeated assistant output");
			return;
		}

		state.runCount += 1;
		persistState();
		updateStatus(ctx);

		pi.sendMessage(
			{
				customType: "auto-continue",
				content: buildAutoContinuePrompt(state.prompt),
				display: false,
			},
			{
				triggerTurn: true,
			},
		);
	});
}
