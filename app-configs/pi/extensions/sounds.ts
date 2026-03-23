import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const SOUNDS = {
  alert: "/System/Library/Sounds/Funk.aiff",
  complete: "/System/Library/Sounds/Hero.aiff",
} as const;

export type SoundName = keyof typeof SOUNDS;

export function createSoundPlayer(pi: ExtensionAPI) {
  return async function playSound(name: SoundName) {
    process.stderr.write("\x07"); // terminal bell
    try {
      await pi.exec("afplay", [SOUNDS[name]], { timeout: 5000 });
    } catch {
      // Ignore errors (e.g., sound file missing)
    }
  };
}
