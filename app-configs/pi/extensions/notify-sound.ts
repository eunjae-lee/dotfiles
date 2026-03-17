import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const SOUND = "/System/Library/Sounds/Hero.aiff";

export default function (pi: ExtensionAPI) {
  async function playSound() {
    try {
      await pi.exec("afplay", [SOUND], { timeout: 5000 });
    } catch {
      // Ignore errors (e.g., sound file missing)
    }
  }

  pi.on("agent_end", async (_event, ctx) => {
    if (!ctx.isIdle()) return;
    await playSound();
  });

  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("🔔 Notification sound extension loaded", "info");
  });
}
