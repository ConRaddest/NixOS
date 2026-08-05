{ ... }:

{
  flake.lib.homeModules.fzf =
    { config, pkgs, ... }:

    let
      fzf = pkgs.symlinkJoin {
        name = "fzf-dms";
        inherit (pkgs.fzf) version;
        meta.mainProgram = "fzf";
        paths = [ pkgs.fzf ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/fzf" \
            --set FZF_DEFAULT_OPTS_FILE "${config.xdg.configHome}/fzf/dms-options"
        '';
      };
    in
    {
      programs.fzf = {
        enable = true;
        package = fzf;
        enableBashIntegration = true;
      };

      home.sessionVariables.FZF_DEFAULT_OPTS_FILE = "${config.xdg.configHome}/fzf/dms-options";

      xdg.configFile."matugen/templates/fzf-options".text = ''
        --color=fg:{{colors.on_surface.default.hex}},hl:{{colors.primary.default.hex}},fg+:{{colors.on_surface.default.hex}},hl+:{{colors.primary.default.hex}},info:{{colors.secondary.default.hex}},prompt:{{colors.primary.default.hex}},pointer:{{colors.primary.default.hex}},marker:{{colors.secondary.default.hex}},spinner:{{colors.tertiary.default.hex}},header:{{colors.on_surface_variant.default.hex}},border:{{colors.outline.default.hex}},label:{{colors.on_surface_variant.default.hex}},query:{{colors.on_surface.default.hex}}
      '';
    };
}
