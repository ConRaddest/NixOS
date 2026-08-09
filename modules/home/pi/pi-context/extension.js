const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const vscode = require("vscode");

const heartbeatMs = 1_000;
const maxStateAgeMs = 30_000;
let statePath;
let heartbeat;
let cleanup;

function getStateDirectory() {
  const configured = vscode.workspace.getConfiguration("piVscodeContext").get("directory");
  if (configured) return configured.replace(/^~(?=$|[\\/])/, os.homedir());
  if (process.env.PI_VSCODE_CONTEXT_DIR) return process.env.PI_VSCODE_CONTEXT_DIR;
  return path.join(process.env.XDG_CACHE_HOME || path.join(os.homedir(), ".cache"), "pi-vscode-context");
}

function getFileUri(tab) {
  const input = tab.input;
  if (!input || !input.uri || input.uri.scheme !== "file") return undefined;
  return input.uri;
}

function getLineRange(range) {
  const start = range.start.line + 1;
  const end = range.end.line + (range.end.character > 0 ? 1 : 0);
  return { start, end: Math.max(start, end) };
}

function getDiagnosticCode(code) {
  if (code === undefined) return undefined;
  if (typeof code === "object" && code !== null && "value" in code) return String(code.value);
  return String(code);
}

function getState() {
  const files = [];
  for (const group of vscode.window.tabGroups.all) {
    for (const tab of group.tabs) {
      const uri = getFileUri(tab);
      if (uri && !files.includes(uri.fsPath)) files.push(uri.fsPath);
    }
  }

  const activeEditor = vscode.window.activeTextEditor;
  const activeUri = activeEditor?.document.uri;
  const activeFile = activeUri && activeUri.scheme === "file" ? activeUri.fsPath : undefined;
  const selections = activeEditor?.selections
    .map((selection, index) => selection.isEmpty ? undefined : {
      ...getLineRange(selection),
      text: activeEditor.document.getText(selection),
      primary: index === 0
    })
    .filter(Boolean) ?? [];
  const cursorLine = selections.length === 0 && activeEditor
    ? activeEditor.selection.active.line + 1
    : undefined;
  const diagnostics = activeUri && activeUri.scheme === "file" && !activeEditor.document.isDirty
    ? vscode.languages
        .getDiagnostics(activeUri)
        .filter(
          (diagnostic) =>
            diagnostic.severity === vscode.DiagnosticSeverity.Error ||
            diagnostic.severity === vscode.DiagnosticSeverity.Warning
        )
        .map((diagnostic) => ({
          file: activeUri.fsPath,
          severity: diagnostic.severity === vscode.DiagnosticSeverity.Error ? "error" : "warning",
          message: diagnostic.message,
          source: diagnostic.source,
          code: getDiagnosticCode(diagnostic.code),
          ...getLineRange(diagnostic.range)
        }))
    : [];

  return {
    files,
    activeFile,
    cursorLine,
    selections,
    diagnostics,
    updatedAt: Date.now()
  };
}

function removeStaleStates() {
  if (!statePath) return;
  let names;
  try {
    names = fs.readdirSync(path.dirname(statePath)).filter((name) => name.endsWith(".json"));
  } catch {
    return;
  }

  const now = Date.now();
  for (const name of names) {
    const file = path.join(path.dirname(statePath), name);
    if (file === statePath) continue;
    try {
      let updatedAt;
      try {
        updatedAt = JSON.parse(fs.readFileSync(file, "utf8")).updatedAt;
      } catch {
        updatedAt = fs.statSync(file).mtimeMs;
      }
      if (typeof updatedAt !== "number" || now - updatedAt > maxStateAgeMs) fs.unlinkSync(file);
    } catch (error) {
      if (error.code !== "ENOENT") console.error("Pi VS Code Context: failed to remove stale state", error);
    }
  }
}

function writeState() {
  if (!statePath) return;
  const state = getState();
  if (state.files.length === 0) {
    removeState();
    return;
  }
  const temporaryPath = `${statePath}.${process.pid}.tmp`;
  fs.mkdirSync(path.dirname(statePath), { recursive: true, mode: 0o700 });
  fs.writeFileSync(temporaryPath, JSON.stringify(state, null, 2), { encoding: "utf8", mode: 0o600 });
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
  statePath = path.join(getStateDirectory(), `${process.pid}.json`);

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
    vscode.window.onDidChangeTextEditorSelection(update),
    vscode.workspace.onDidChangeTextDocument(update),
    vscode.workspace.onDidSaveTextDocument(update),
    vscode.languages.onDidChangeDiagnostics(update),
    vscode.commands.registerCommand("pi-vscode-context.refresh", update),
    new vscode.Disposable(() => {
      clearInterval(heartbeat);
      clearInterval(cleanup);
      removeState();
    })
  );

  removeStaleStates();
  update();
  heartbeat = setInterval(update, heartbeatMs);
  cleanup = setInterval(removeStaleStates, maxStateAgeMs);
}

function deactivate() {
  clearInterval(heartbeat);
  clearInterval(cleanup);
  removeState();
}

module.exports = { activate, deactivate };
