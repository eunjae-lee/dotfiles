import type { AgentMessage } from "@mariozechner/pi-agent-core";
import type { AssistantMessage, TextContent } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { createSoundPlayer } from "../lib/sounds.ts";

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

function getLastAssistantText(messages: AgentMessage[]): string {
  const lastAssistant = [...messages].reverse().find(isAssistantMessage);
  return lastAssistant ? getTextContent(lastAssistant) : "";
}

function needsAttention(text: string): boolean {
  return /\?/.test(text) || /\b(confirm|choose|clarify|decide|let me know|which|what should|would you like|can you|could you|please provide)\b/i.test(text);
}

export default function (pi: ExtensionAPI) {
  const playSound = createSoundPlayer(pi);
  let questionSoundPlayedThisRun = false;

  pi.on("agent_start", async () => {
    questionSoundPlayedThisRun = false;
  });

  pi.on("message_end", async (event) => {
    if (!isAssistantMessage(event.message)) return;

    const assistantText = getTextContent(event.message);
    if (!needsAttention(assistantText)) return;
    if (questionSoundPlayedThisRun) return;

    questionSoundPlayedThisRun = true;
    await playSound("alert");
  });

  pi.on("agent_end", async (event, ctx) => {
    if (!ctx.isIdle()) return;
    if (questionSoundPlayedThisRun) return;

    const assistantText = getLastAssistantText(event.messages);
    const attentionNeeded = needsAttention(assistantText);

    await playSound(attentionNeeded ? "alert" : "complete");
  });
}
