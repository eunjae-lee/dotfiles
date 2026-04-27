import type { AgentMessage } from "@mariozechner/pi-agent-core";
import type { AssistantMessage, TextContent } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

type AutoContinueState = {
	enabled: boolean;
	waitingForInput: boolean;
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
	waitingForInput: false,
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
	return `${base}\n\nAuto-continue instructions:\n- Do not ask whether you should continue.\n- If you can continue autonomously, continue with the next concrete action.\n- If you need user input, ask the specific question now and end your response with exactly [NEEDS_USER_INPUT].\n- If the task is fully complete, end your response with exactly [TASK_COMPLETE].`;
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
		const pauseLabel = state.waitingForInput ? " paused" : "";
		const label = `∞ auto-continue${promptLabel}${pauseLabel} ${state.runCount}/${state.maxRuns}`;
		ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("accent", label));
	}

	function stop(ctx: ExtensionContext, reason: string) {
		state.enabled = false;
		persistState();
		updateStatus(ctx);
		ctx.ui.notify(`Auto-continue stopped: ${reason}`, "info");
	}

	function queueAutoContinue(ctx: ExtensionContext) {
		const message = {
			customType: "auto-continue",
			content: buildAutoContinuePrompt(state.prompt),
			display: false,
		} as const;

		if (ctx.isIdle()) {
			pi.sendMessage(message, { triggerTurn: true });
			ctx.ui.notify("Auto-continue queued", "info");
		} else {
			pi.sendMessage(message, { deliverAs: "followUp", triggerTurn: true });
			ctx.ui.notify("Auto-continue queued as follow-up", "info");
		}
	}

	pi.registerCommand("autocontinue", {
		description: "Enable auto-continue mode with an optional stored prompt",
		handler: async (args, ctx) => {
			const prompt = args.trim() || state.prompt.trim();
			const effectivePrompt = buildAutoContinuePrompt(prompt);

			state.enabled = true;
			state.waitingForInput = false;
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
			state.waitingForInput = false;
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
				`Auto-continue: on${state.waitingForInput ? " (paused for input)" : ""} (${state.runCount}/${state.maxRuns})\nPrompt: ${state.prompt || "<default>"}`,
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

	pi.on("input", async (event, ctx) => {
		if (event.source === "interactive" || event.source === "rpc") {
			const wasWaitingForInput = state.waitingForInput;
			state.waitingForInput = false;
			state.runCount = 0;
			state.lastAssistantText = undefined;
			state.repeatCount = 0;
			persistState();
			updateStatus(ctx);

			if (wasWaitingForInput && state.enabled) {
				ctx.ui.notify("Auto-continue resumed", "info");
			}
		}
		return { action: "continue" as const };
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
			state.waitingForInput = true;
			persistState();
			updateStatus(ctx);
			ctx.ui.notify("Auto-continue paused: waiting for your input", "info");
			return;
		}

		if (state.waitingForInput) {
			updateStatus(ctx);
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

		queueAutoContinue(ctx);
	});
}
