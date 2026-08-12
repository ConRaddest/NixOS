{ ... }:

{
  flake.lib.homeModules.yazi =
    { config, pkgs, ... }:

    let
      theme = config.nos.theme.colors;
      yaziWrapper = pkgs.writeShellScriptBin "yazi-wrapper.sh" ''
        multiple="$1"
        directory="$2"
        save="$3"
        path="$4"
        out="$5"

        log="/tmp/yazi-chooser.log"
        echo "--- $(date) ---"       >> "$log"
        echo "multiple=$multiple"    >> "$log"
        echo "directory=$directory"  >> "$log"
        echo "save=$save"            >> "$log"
        echo "path=$path"            >> "$log"

        termcmd="''${TERMCMD:-kitty --title termfilechooser -e}"

        : > "$out"
        $termcmd yazi --chooser-file="$out" ''${path:+"$path"} || true

        echo "result=$(cat "$out" 2>/dev/null || echo empty)" >> "$log"

        if [ -s "$out" ] && [ "$directory" != "1" ] && [ "$save" != "1" ]; then
          selected=$(head -1 "$out")
          if [ -d "$selected" ]; then
            : > "$out"
          fi
        fi

        [ -s "$out" ] || : > "$out"
        exit 0
      '';
    in
    {
      # Custom config below renders semantic colors directly.
      stylix.targets.yazi.enable = false;

      home.packages = with pkgs; [
        imv
        mpv
        yaziWrapper
      ];

      programs.yazi = {
        enable = true;
        settings = {
          mgr = {
            ratio = [
              2
              4
              3
            ];
            show_hidden = false;
          };

          opener = {
            edit = [
              {
                run = "nvim %*";
                block = true;
                desc = "Neovim";
              }
            ];
            view = [
              {
                run = "uwsm app -- imv %*";
                block = false;
                desc = "imv";
              }
              {
                run = "xdg-open %*";
                block = false;
                desc = "Open";
              }
            ];
            play = [
              {
                run = "uwsm app -- mpv %*";
                block = false;
                desc = "mpv";
              }
            ];
            open = [
              {
                run = "xdg-open %*";
                block = false;
                desc = "Open";
              }
            ];
          };

          open.rules = [
            {
              mime = "inode/x-empty";
              use = [ "edit" ];
            }
            {
              mime = "text/*";
              use = [ "edit" ];
            }
            {
              mime = "application/{json,ld+json,javascript,typescript,x-yaml,toml,xml,x-sh,x-shellscript}";
              use = [ "edit" ];
            }
            {
              url = "*.{md,markdown,txt,log,csv,tsv,json,jsonc,yml,yaml,toml,xml,html,css,js,jsx,ts,tsx,py,sh,bash,zsh,lua,nix,rs,go,c,cpp,h,hpp}";
              use = [ "edit" ];
            }
            {
              mime = "image/*";
              use = [
                "view"
                "edit"
              ];
            }
            {
              mime = "{audio,video}/*";
              use = [ "play" ];
            }
            {
              mime = "*";
              use = [ "open" ];
            }
          ];
        };
      };

      xdg = {
        configFile = {
          "xdg-desktop-portal-termfilechooser/config" = {
            text = ''
              [filechooser]
              cmd=yazi-wrapper.sh
              default_dir=$HOME
              env=TERMCMD=kitty --class termfilechooser --title FileChooser -e
              open_mode=suggested
              save_mode=suggested
              create_help_file=1
            '';
          };
          "yazi/theme.toml" = {
            source = pkgs.replaceVars ./theme.toml {
              inherit (theme)
                accent
                bright_foreground
                cyan
                foreground
                green
                muted
                red
                selection
                yellow
                ;
            };
          };
        };
        desktopEntries = {
          yazi = {
            categories = [
              "System"
              "FileManager"
              "FileTools"
            ];
            comment = "Terminal file manager";
            exec = "kitty --class yazi --title yazi -e yazi %f";
            icon = "yazi";
            mimeType = [
              "inode/directory"
              "application/x-directory"
            ];
            name = "Yazi";
            terminal = false;
            type = "Application";
          };
        };
        mimeApps = {
          defaultApplications = {
            "application/x-directory" = "yazi.desktop";
            "image/avif" = "imv.desktop";
            "image/bmp" = "imv.desktop";
            "image/gif" = "imv.desktop";
            "image/heif" = "imv.desktop";
            "image/jpeg" = "imv.desktop";
            "image/jpg" = "imv.desktop";
            "image/jxl" = "imv.desktop";
            "image/pjpeg" = "imv.desktop";
            "image/png" = "imv.desktop";
            "image/qoi" = "imv.desktop";
            "image/svg+xml" = "imv.desktop";
            "image/tiff" = "imv.desktop";
            "image/tiff-fx" = "imv.desktop";
            "image/webp" = "imv.desktop";
            "image/x-bmp" = "imv.desktop";
            "image/x-farbfeld" = "imv.desktop";
            "image/x-png" = "imv.desktop";
            "inode/directory" = "yazi.desktop";
          };
          enable = true;
        };
      };
    };
}
