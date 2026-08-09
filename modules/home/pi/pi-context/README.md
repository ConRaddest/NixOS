# Pi VS Code Context

Small bridge between VS Code and pi.

VS Code writes open files, active file, cursor line, selected line ranges and text, and saved active-file diagnostics to `~/.cache/pi-vscode-context`. Diagnostics are omitted while the active file has unsaved changes. Pi reads every live, non-empty state before each agent turn and adds a compact summary to its system prompt, regardless of pi's current directory.

## Install

Home Manager installs both sides from `modules/home/pi/default.nix`:

```bash
home-manager switch --flake .#<profile>
```

Restart VS Code after first install. For manual use, link this directory into:

```text
~/.vscode/extensions/local.pi-vscode-context-0.1.0
```

Use `Pi: Refresh VS Code Context` from Command Palette to force an update. Pi also provides `/vscode` to inspect received context.

State updates immediately after editor, selection, document, diagnostic, or tab changes, plus a one-second heartbeat. State expires after 30 seconds without a heartbeat. Stale cache files are deleted automatically; states with no open files are removed and never added to the prompt.

Files stay local with no network communication. Cache files use owner-only permissions because selections can contain source code and secrets.
