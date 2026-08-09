# Pi VS Code Context

Small bridge between VS Code and pi.

VS Code writes current file tabs to `~/.cache/pi-vscode-context`. Pi reads matching state before each agent turn and adds open files plus active file to its system prompt.

## Install

Home Manager installs both sides from `home/pi.nix`:

```bash
home-manager switch --flake .#<profile>
```

Restart VS Code after first install. For manual use, link this directory into:

```text
~/.vscode/extensions/local.pi-vscode-context-0.1.0
```

Use `Pi: Refresh VS Code Context` from Command Palette to force an update. Pi also provides `/vscode` to inspect received context.

State expires after 30 seconds without a VS Code heartbeat. Files stay local; no network communication.
