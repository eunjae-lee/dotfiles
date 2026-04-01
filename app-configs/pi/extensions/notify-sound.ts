import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { createSoundPlayer } from "../lib/sounds.ts";

const isInsideCmux = () =>
  !!process.env.CMUX_WORKSPACE_ID && !!process.env.CMUX_SOCKET_PATH;

export default function (pi: ExtensionAPI) {
  const playSound = createSoundPlayer(pi);

  pi.on("agent_end", async (_event, ctx) => {
    if (!ctx.isIdle()) return;
    await playSound("complete");

    if (isInsideCmux()) {
      try {
        await pi.exec("bash", [
          "-c",
          `echo '{"notification":{"title":"pi","body":"Task complete"}}' | cmux claude-hook notification`,
        ], { timeout: 5000 });
      } catch {
        // Ignore — cmux CLI might not be available
      }
    }
  });
}
