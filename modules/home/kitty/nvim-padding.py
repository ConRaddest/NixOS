import os
import shlex

neovim_windows = set()


def is_neovim(cmdline):
    try:
        command = shlex.split(cmdline)
    except ValueError:
        command = cmdline.split()

    if not command:
        return False

    return os.path.basename(command[0]) in {"nvim", "vim", "vi"}


def set_padding(boss, window, padding):
    boss.call_remote_control(
        window,
        (
            "set-spacing",
            f"--match=id:{window.id}",
            f"padding={padding}",
        ),
    )


def on_cmd_startstop(boss, window, data):
    if data["is_start"] and is_neovim(data["cmdline"]):
        neovim_windows.add(window.id)
        set_padding(boss, window, "0")
    elif not data["is_start"] and window.id in neovim_windows:
        neovim_windows.remove(window.id)
        set_padding(boss, window, "default")
