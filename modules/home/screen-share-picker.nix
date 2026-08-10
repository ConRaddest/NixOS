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
      colors = config.lib.stylix.colors.withHashtag;
    in
    {
      home.packages = [ pickerPackage ];

      xdg.configFile."hyprland-preview-share-picker/config.yaml".text = ''
        stylesheets: ["${stylesheet}"]
        default_page: outputs

        window:
          height: 420
          width: 1000

        image:
          resize_size: 500
          widget_size: 150

        classes:
          window: window
          image_card: card
          image_card_loading: card-loading
          image: image
          image_label: image-label
          notebook: notebook
          tab_label: tab-label
          notebook_page: page
          region_button: region-button
          restore_button: restore-button

        windows:
          min_per_row: 3
          max_per_row: 999
          clicks: 1
          spacing: 12

        outputs:
          clicks: 1
          spacing: 6
          show_label: false
          respect_output_scaling: true

        region:
          command: slurp -f '%o@%x,%y,%w,%h'

        hide_token_restore: true
        debug: false
      '';

      xdg.configFile."hyprland-preview-share-picker/hyprland-preview-share-picker.css".text = ''
        @define-color foreground ${colors.base05};
        @define-color background ${colors.base00};
        @define-color accent ${colors.base0D};
        @define-color muted ${colors.base04};
        @define-color card_bg ${colors.base01};
        @define-color text_dark ${colors.base00};
        @define-color accent_hover ${colors.base0D};
        @define-color accent_hover_text ${colors.base00};
        @define-color selected_tab ${colors.base0D};
        @define-color text ${colors.base05};
        @define-color shadow #000000;

        * {
          all: unset;
          font-family: "${font.mono}";
          color: @foreground;
          font-weight: bold;
          font-size: 16px;
        }

        .window {
          background: alpha(@background, ${backgroundOpacity});
          margin: 4px;
          padding: 6px;
        }

        tabs {
          padding: 0.5rem 1rem;
        }

        tabs > tab {
          margin-right: 1rem;
        }

        .tab-label {
          color: @text;
          transition: all 0.2s ease;
        }

        tabs > tab:checked > .tab-label, tabs > tab:active > .tab-label {
          color: @selected_tab;
        }

        tabs > tab:focus > .tab-label {
          color: @foreground;
        }

        .page {
          padding: 1rem;
        }

        .image-label {
          font-size: 12px;
          background-color: transparent;
          padding: 0.25rem 0;
          margin-top: 0.25rem;
        }

        flowboxchild > .card, button > .card {
          transition: all 0.2s ease;
          border: solid 2px transparent;
          border-radius: 5px;
          background-color: transparent;
          padding: 0;
        }

        flowboxchild:hover > .card, button:hover > .card, flowboxchild:active > .card, flowboxchild:selected > .card, button:active > .card, button:selected > .card, button:focus > .card {
          border-color: @accent;
        }

        .image {
          border-radius: 5px;
          box-shadow: 0 4px 30px alpha(@shadow, 0.33);
        }

        .region-button {
          padding: 0.5rem 1rem;
          border-radius: 5px;
          background-color: @accent;
          color: @text_dark;
          transition: all 0.2s ease;
        }

        .region-button > label {
          color: @text_dark;
        }

        .region-button:not(:disabled):hover, .region-button:not(:disabled):focus {
          background-color: @accent_hover;
          color: @accent_hover_text;
        }

        .region-button:not(:disabled):hover > label, .region-button:not(:disabled):focus > label {
          color: @accent_hover_text;
        }

        .region-button:disabled {
          background-color: @muted;
          color: @background;
        }
      '';

      xdg.configFile."hypr/xdph.conf".text = ''
        screencopy {
          custom_picker_binary = hyprland-preview-share-picker
        }
      '';
    };
}
