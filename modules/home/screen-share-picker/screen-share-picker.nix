{ ... }:

{
  flake.lib.homeModules.screenSharePicker =
    {
      config,
      pkgs,
      inputs,
      font,
      ...
    }:

    let
      cfgDir = "${config.xdg.configHome}/hyprland-preview-share-picker";
      stylesheet = "${cfgDir}/hyprland-preview-share-picker.css";
      backgroundOpacity = "0.95";
      pickerPackage =
        inputs.hyprland-preview-share-picker.packages.${pkgs.stdenv.hostPlatform.system}.default;
      colors = config.nos.theme.colors;
    in
    {
      home.packages = [ pickerPackage ];

      xdg = {
        configFile."hyprland-preview-share-picker/config.yaml".source = pkgs.replaceVars ./config.yaml {
          inherit stylesheet;
        };
      };

      xdg.configFile."hyprland-preview-share-picker/hyprland-preview-share-picker.css".source =
        pkgs.replaceVars ./style.gtkcss.in
          {
            inherit backgroundOpacity;
            inherit (colors)
              accent
              background
              dark_background
              foreground
              muted
              ;
            fontMono = font.mono;
          };

      xdg.configFile."hypr/xdph.conf".text = ''
        screencopy {
          custom_picker_binary = hyprland-preview-share-picker
        }
      '';
    };
}
