/**
 * Custom Footer Extension — Enhanced status bar
 *
 * Displays: in/out tokens, context%, cwd, PR number, git branch, model
 * Color-coded context usage: green <50%, yellow 50-75%, red >75%
 */

import { execSync } from "child_process";
import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

export default function (pi: ExtensionAPI) {
	function fmt(n: number): string {
		if (n < 1000) return `${n}`;
		return `${(n / 1000).toFixed(1)}k`;
	}

	pi.on("session_start", async (_event, ctx) => {
		ctx.ui.setFooter((tui, theme, footerData) => {
			let prNumber: string | null = null;

			function fetchPrNumber() {
				try {
					const out = execSync("gh pr view --json number --jq .number 2>/dev/null", {
						encoding: "utf-8",
						timeout: 5000,
					}).trim();
					prNumber = out || null;
				} catch {
					prNumber = null;
				}
			}

			fetchPrNumber();
			const unsub = footerData.onBranchChange(() => {
				fetchPrNumber();
				tui.requestRender();
			});

			return {
				dispose() { unsub(); },
				invalidate() {},
				render(width: number): string[] {
					let input = 0, output = 0;
					for (const e of ctx.sessionManager.getBranch()) {
						if (e.type === "message" && e.message.role === "assistant") {
							const m = e.message as AssistantMessage;
							input += m.usage.input;
							output += m.usage.output;
						}
					}

					const usage = ctx.getContextUsage();
					const pct = usage?.percent ?? 0;

					const pctColor = pct > 75 ? "error" : pct > 50 ? "warning" : "success";

					const tokenStats = [
						theme.fg("accent", `${fmt(input)}/${fmt(output)}`),
						theme.fg(pctColor, `${pct.toFixed(0)}%`),
					].join(" ");

						const parts = process.cwd().split("/");
					const short = parts.length > 2 ? parts.slice(-2).join("/") : process.cwd();
					const cwdStr = theme.fg("muted", `⌂ ${short}`);

					const prStr = prNumber ? theme.fg("success", `#${prNumber}`) : "";

					const branch = footerData.getGitBranch();
					const branchStr = branch ? theme.fg("accent", `⎇ ${branch}`) : "";

					const thinking = pi.getThinkingLevel();
					const thinkColor = thinking === "high" ? "warning" : thinking === "medium" ? "accent" : thinking === "low" ? "dim" : "muted";
					const modelId = ctx.model?.id || "no-model";
					const modelStr = theme.fg(thinkColor, "◆") + " " + theme.fg("accent", modelId);

					const sep = theme.fg("dim", " | ");
					const leftParts = [modelStr, tokenStats, cwdStr];
					if (prStr) leftParts.push(prStr);
					if (branchStr) leftParts.push(branchStr);
					const left = leftParts.join(sep);

					return [truncateToWidth(left, width)];
				},
			};
		});
	});


}
