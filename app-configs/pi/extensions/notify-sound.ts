import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { createSoundPlayer } from "../lib/sounds.ts";

const isInsideCmux = () =>
  !!process.env.CMUX_WORKSPACE_ID && !!process.env.CMUX_SOCKET_PATH;

function cmuxHook(pi: ExtensionAPI, args: string, stdin?: string) {
  const cmd = stdin
    ? `echo '${stdin.replace(/'/g, "'\\''")}' | cmux claude-hook ${args}`
    : `echo '{}' | cmux claude-hook ${args}`;
  return pi.exec("bash", ["-c", cmd], { timeout: 5000 }).catch(() => {});
}

export default function (pi: ExtensionAPI) {
  const playSound = createSoundPlayer(pi);

  pi.on("agent_start", async (_event) => {
    if (isInsideCmux()) {
      await cmuxHook(pi, "session-start");
    }
  });

  pi.on("agent_end", async (_event, ctx) => {
    if (!ctx.isIdle()) return;
    await playSound("complete");

    if (isInsideCmux()) {
      await cmuxHook(pi, "notification", JSON.stringify({
        notification: { title: "pi", body: "Task complete" },
      }));
      await cmuxHook(pi, "stop");
    }
  });
}
