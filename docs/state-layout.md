# Runtime state layout

NOS runtime data follows XDG directory ownership:

- `$XDG_CONFIG_HOME/nos/`: intentional mutable user config not managed by Nix.
- `$XDG_STATE_HOME/nos/`: persistent operation and future desktop-shell state.
- `$XDG_CACHE_HOME/nos/`: disposable indexes, previews, and downloaded metadata.
- `$XDG_RUNTIME_DIR/nos/`: locks, sockets, and temporary session handshakes.

Current operation lock is `$XDG_RUNTIME_DIR/nos/operation.lock`. When runtime directory is unavailable, commands use `/tmp/nos-$UID/nos/operation.lock`.

Repository configuration remains under `$NOS_DIR`; runtime state must not be written into Nix-managed module paths unless command intentionally edits declarative configuration.
