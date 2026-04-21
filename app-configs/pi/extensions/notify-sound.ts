import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { createSoundPlayer } from "../lib/sounds.ts";

export default function (pi: ExtensionAPI) {
  const playSound = createSoundPlayer(pi);

  pi.on("agent_end", async (_event, ctx) => {
    if (!ctx.isIdle()) return;
    await playSound("complete");
  });
}
