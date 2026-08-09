const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const vscode = require("vscode");

const heartbeatMs = 5_000;
let statePath;
let heartbeat;

function getStateDirectory() {
  const configured = vscode.workspace.getConfiguration("piVscodeContext").get("directory");
  if (configured) return configured.replace(/^~(?=$|[\\/])/, os.homedir());
  if (process.env.PI_VSCODE_CONTEXT_DIR) return process.env.PI_VSCODE_CONTEXT_DIR;
  return path.join(process.env.XDG_CACHE_HOME || path.join(os.homedir(), ".cache"), "pi-vscode-context");
}

function getWorkspaceRoots() {
  return (vscode.workspace.workspaceFolders || []).map((folder) => folder.uri.fsPath);
}

function getFileUri(tab) {
  const input = tab.input;
  if (!input || !input.uri || input.uri.scheme !== "file") return undefined;
  return input.uri;
}

function getState() {
  const files = [];
  for (const group of vscode.window.tabGroups.all) {
    for (const tab of group.tabs) {
      const uri = getFileUri(tab);
      if (uri && !files.includes(uri.fsPath)) files.push(uri.fsPath);
    }
  }

  const activeUri = vscode.window.activeTextEditor?.document.uri;
  return {
    workspaceRoots: getWorkspaceRoots(),
    files,
    activeFile: activeUri && activeUri.scheme === "file" ? activeUri.fsPath : undefined,
    updatedAt: Date.now()
  };
}

function writeState() {
  if (!statePath) return;
  const state = JSON.stringify(getState(), null, 2);
  const temporaryPath = `${statePath}.${process.pid}.tmp`;
  fs.mkdirSync(path.dirname(statePath), { recursive: true });
  fs.writeFileSync(temporaryPath, state, "utf8");
  fs.renameSync(temporaryPath, statePath);
}

function removeState() {
  if (!statePath) return;
  try {
    fs.unlinkSync(statePath);
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
}

function activate(context) {
  const roots = getWorkspaceRoots().join("\0") || "no-workspace";
  const id = crypto.createHash("sha256").update(`${roots}\0${process.pid}`).digest("hex").slice(0, 24);
  statePath = path.join(getStateDirectory(), `${id}.json`);

  const update = () => {
    try {
      writeState();
    } catch (error) {
      console.error("Pi VS Code Context: failed to write state", error);
    }
  };

  context.subscriptions.push(
    vscode.window.tabGroups.onDidChangeTabs(update),
    vscode.window.tabGroups.onDidChangeTabGroups(update),
    vscode.window.onDidChangeActiveTextEditor(update),
    vscode.workspace.onDidChangeWorkspaceFolders(update),
    vscode.commands.registerCommand("pi-vscode-context.refresh", update),
    new vscode.Disposable(() => {
      clearInterval(heartbeat);
      removeState();
    })
  );

  update();
  heartbeat = setInterval(update, heartbeatMs);
}

function deactivate() {
  clearInterval(heartbeat);
  removeState();
}

module.exports = { activate, deactivate };
