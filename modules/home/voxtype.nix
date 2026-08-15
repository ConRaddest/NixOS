{ ... }:

{
  flake.lib.homeModules.voxtype =
    { lib, pkgs, ... }:

    let
      package = pkgs.voxtype-vulkan;
      model = pkgs.fetchurl {
        url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin";
        hash = "sha256-oDd5yG3zMjB19eeWyyzlAp8A7Ihp7uP9+4l6/jbG0AI=";
      };
      configFile = (pkgs.formats.toml { }).generate "voxtype-config.toml" {
        state_file = "auto";

        hotkey.enabled = false;

        audio = {
          device = "default";
          sample_rate = 16000;
          max_duration_secs = 60;
          pause_media = true;
          feedback = {
            enabled = true;
            theme = "subtle";
            volume = 0.7;
          };
        };

        whisper = {
          model = toString model;
          language = "en";
          translate = false;
          on_demand_loading = false;
        };

        output = {
          mode = "type";
          fallback_to_clipboard = true;
          type_delay_ms = 1;
          pre_type_delay_ms = 100;
          notification = {
            on_recording_start = false;
            on_recording_stop = false;
            on_transcription = false;
          };
        };

        text.spoken_punctuation = true;
      };
      voxtype = lib.getExe package;
    in
    {
      home.packages = [ package ];

      xdg.configFile = {
        "voxtype/config.toml".source = configFile;
        "hypr/nix/voxtype.lua".text = ''
          hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("${voxtype} record toggle"), {
            desc = "Toggle dictation",
          })
          hl.bind("F9", hl.dsp.exec_cmd("${voxtype} record start"), {
            desc = "Start dictation",
          })
          hl.bind("F9", hl.dsp.exec_cmd("${voxtype} record stop"), {
            desc = "Stop dictation",
            release = true,
          })
        '';
      };

      systemd.user.services.voxtype = {
        Unit = {
          Description = "Voxtype voice-to-text daemon";
          Documentation = "https://voxtype.io";
          PartOf = [ "graphical-session.target" ];
          After = [
            "graphical-session.target"
            "pipewire.service"
            "pipewire-pulse.service"
          ];
        };

        Service = {
          ExecStart = "${voxtype} daemon";
          Restart = "on-failure";
          RestartSec = 5;
        };

        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
