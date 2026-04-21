import type { AgentMessage } from "@mariozechner/pi-agent-core";
import type { AssistantMessage, TextContent } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { createSoundPlayer } from "../lib/sounds.ts";

function notifyOSC777(title: string, body: string): void {
  process.stdout.write(`\x1b]777;notify;${title};${body}\x07`);
}

function notifyOSC99(title: string, body: string): void {
  process.stdout.write(`\x1b]99;i=1:d=0;${title}\x1b\\`);
  process.stdout.write(`\x1b]99;i=1:p=body;${body}\x1b\\`);
}

function notify(title: string, body: string): void {
  if (process.env.KITTY_WINDOW_ID) {
    notifyOSC99(title, body);
    return;
  }

  notifyOSC777(title, body);
}

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

function truncate(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text;
  return `${text.slice(0, maxLength - 1).trimEnd()}…`;
}

function toNotificationBody(text: string): string {
  const singleLine = text.replace(/\s+/g, " ").trim();
  return truncate(singleLine || "Ready for input", 140);
}

function needsAttention(text: string): boolean {
  return /\?/.test(text) || /\b(confirm|choose|clarify|decide|let me know|which|what should|would you like|can you|could you|please provide)\b/i.test(text);
}

export default function (pi: ExtensionAPI) {
  const playSound = createSoundPlayer(pi);

  pi.on("agent_end", async (event, ctx) => {
    if (!ctx.isIdle()) return;

    const assistantText = getLastAssistantText(event.messages);
    const attentionNeeded = needsAttention(assistantText);

    await playSound(attentionNeeded ? "alert" : "complete");
    notify(attentionNeeded ? "Pi needs your input" : "Pi is ready", toNotificationBody(assistantText));
  });
}
