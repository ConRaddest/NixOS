# NOS command contract

Command registry lives in `modules/home/bin.nix`. Each command declares:

- route and executable name
- source script
- summary
- runtime inputs
- command-specific environment

Registry generates direct `nos-*` executables, `nos` router help, and `$XDG_DATA_HOME/nos/commands.json` for future shell UI.

## Entry points

Both forms remain supported:

```bash
nos build
nos-build
```

Nested route:

```bash
nos host new
```

## Script rules

- Use `set -euo pipefail`.
- Source shared code from `$NOS_RUNTIME_DIR`.
- Use `$NOS_DIR` only for mutable repository content.
- Declare external commands in registry `runtimeInputs`.
- Use `nos_operation_lock` before mutating configuration or activating generations.
- Preserve files on failed mutation.
- Keep user-facing errors short and send diagnostics to stderr.

Helper scripts such as `nos-ui.sh` and `nos-apps.sh` are packaged in runtime tree but are not exposed as commands.
