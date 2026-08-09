import { readdirSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join, relative, resolve, sep } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type VscodeState = {
	workspaceRoots?: string[];
	files?: string[];
	activeFile?: string;
	updatedAt?: number;
};

const stateDirectory =
	process.env.PI_VSCODE_CONTEXT_DIR ?? join(process.env.XDG_CACHE_HOME ?? join(homedir(), ".cache"), "pi-vscode-context");
const maxStateAge = 30_000;

function isInside(root: string, file: string): boolean {
	const path = relative(root, file);
	return path === "" || (!path.startsWith(`..${sep}`) && path !== ".." && !path.includes(`..${sep}`));
}

function readStates(cwd: string): VscodeState[] {
	let names: string[];

	try {
		names = readdirSync(stateDirectory).filter((name) => name.endsWith(".json"));
	} catch {
		return [];
	}

	const now = Date.now();
	const states: VscodeState[] = [];

	for (const name of names) {
		try {
			const state = JSON.parse(readFileSync(join(stateDirectory, name), "utf8")) as VscodeState;
			const roots = (state.workspaceRoots ?? []).map((root) => resolve(root));
			const files = (state.files ?? []).map((file) => resolve(file));
			if (!state.updatedAt || now - state.updatedAt > maxStateAge) continue;
			if (roots.length > 0 && !roots.some((root) => isInside(root, cwd) || isInside(cwd, root))) continue;
			if (roots.length === 0 && !files.some((file) => isInside(cwd, file))) continue;
			states.push({ ...state, files });
		} catch {
			// Ignore files being replaced or malformed state files.
		}
	}

	return states;
}

function getOpenFiles(cwd: string): { files: string[]; activeFile?: string } {
	const files = new Set<string>();
	let activeFile: string | undefined;

	for (const state of readStates(cwd)) {
		for (const file of state.files ?? []) {
			files.add(resolve(file));
		}
		if (state.activeFile) activeFile = resolve(state.activeFile);
	}

	return { files: [...files].sort(), activeFile };
}

function formatPath(cwd: string, file: string): string {
	const path = relative(cwd, file);
	return path && !path.startsWith("..") ? path : file;
}

export default function vscodeContextExtension(pi: ExtensionAPI) {
	pi.on("before_agent_start", async (event, ctx) => {
		const context = getOpenFiles(ctx.cwd);
		if (context.files.length === 0) return;

		const files = context.files.map((file) => `- ${formatPath(ctx.cwd, file)}`).join("\n");
		const active = context.activeFile ? `\nActive file: ${formatPath(ctx.cwd, context.activeFile)}` : "";

		return {
			systemPrompt: `${event.systemPrompt}\n\n## VS Code context\nCurrently open files:\n${files}${active}\nUse this as orientation. Verify file contents before making changes.`,
		};
	});

	pi.registerCommand("vscode", {
		description: "Show files currently open in VS Code",
		handler: async (_args, ctx) => {
			const context = getOpenFiles(ctx.cwd);
			if (context.files.length === 0) {
				ctx.ui.notify("No current VS Code context", "info");
				return;
			}

			const active = context.activeFile ? `Active: ${formatPath(ctx.cwd, context.activeFile)}\n` : "";
			ctx.ui.notify(`${active}${context.files.map((file) => formatPath(ctx.cwd, file)).join(", ")}`, "info");
		},
	});
}
