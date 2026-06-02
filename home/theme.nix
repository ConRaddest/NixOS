{ ... }:

{
  flake.lib.homeModules.theme =
    {
      pkgs,
      font,
      colors,
      ...
    }:

    let
      folderSvg = ''
        <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
          <path fill="${colors.bgLight}" d="M6 14c0-3.3 2.7-6 6-6h14c2.1 0 4.1 1.1 5.2 2.9L33 14h19c3.3 0 6 2.7 6 6v4H6z"/>
          <path fill="${colors.primary}" d="M6 20c0-3.3 2.7-6 6-6h40c3.3 0 6 2.7 6 6v30c0 3.3-2.7 6-6 6H12c-3.3 0-6-2.7-6-6z"/>
          <path fill="${colors.fgLight}" opacity="0.14" d="M10 22h48v8H6v-4c0-2.2 1.8-4 4-4z"/>
          <path fill="${colors.bgLight}" opacity="0.18" d="M6 46h52v4c0 3.3-2.7 6-6 6H12c-3.3 0-6-2.7-6-6z"/>
        </svg>
      '';
      folderIconNames = [
        "folder"
        "folder-open"
        "folder-documents"
        "folder-download"
        "folder-downloads"
        "folder-music"
        "folder-pictures"
        "folder-publicshare"
        "folder-remote"
        "folder-saved-search"
        "folder-symbolic"
        "folder-templates"
        "folder-videos"
        "user-desktop"
        "user-home"
      ];
    in
    {
      home.packages = with pkgs; [
        xdg-desktop-portal-gtk
        adwaita-qt
        adwaita-qt6
      ];

      qt = {
        enable = true;
        platformTheme.name = "gtk";
        style = {
          name = "adwaita-dark";
          package = pkgs.adwaita-qt;
        };
      };

      dconf.enable = true;

      home.pointerCursor = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
        size = 24;
        gtk.enable = true;
        hyprcursor.enable = true;
      };

      gtk = {
        enable = true;
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
        iconTheme = {
          name = "Nos";
          package = pkgs.adwaita-icon-theme;
        };
        font = {
          name = font.system;
          size = font.size;
        };
        gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk3.extraCss = ''
          @define-color accent_color          ${colors.bg};
          @define-color accent_bg_color       ${colors.bg};
          @define-color accent_fg_color       ${colors.bg};
          @define-color destructive_color     ${colors.red};
          @define-color destructive_bg_color  ${colors.red};
          @define-color destructive_fg_color  ${colors.bg};
          @define-color success_color         ${colors.green};
          @define-color success_bg_color      ${colors.green};
          @define-color warning_color         ${colors.yellow};
          @define-color warning_bg_color      ${colors.yellow};
          @define-color error_color           ${colors.red};
          @define-color error_bg_color        ${colors.red};
          @define-color window_bg_color       ${colors.bg};
          @define-color window_fg_color       ${colors.fg};
          @define-color view_bg_color         ${colors.bg};
          @define-color view_fg_color         ${colors.fg};
          @define-color headerbar_bg_color    ${colors.bg};
          @define-color headerbar_fg_color    ${colors.fg};
          @define-color headerbar_border_color ${colors.bg};
          @define-color headerbar_backdrop_color ${colors.bg};
          @define-color sidebar_bg_color      ${colors.bg};
          @define-color sidebar_fg_color      ${colors.fgDark};
          @define-color sidebar_backdrop_color ${colors.bg};
          @define-color sidebar_border_color  ${colors.bg};
          @define-color card_bg_color         ${colors.bg};
          @define-color card_fg_color         ${colors.fg};
          @define-color popover_bg_color      ${colors.bgLight};
          @define-color popover_fg_color      ${colors.fg};
          @define-color dialog_bg_color       ${colors.bg};
          @define-color dialog_fg_color       ${colors.fg};

          window,
          dialog,
          popover,
          menu,
          .background {
            background-color: @window_bg_color;
            color: @window_fg_color;
          }

          view,
          .view,
          list,
          gridview,
          columnview,
          treeview,
          textview text,
          viewport,
          scrolledwindow {
            background-color: @view_bg_color;
            color: @view_fg_color;
          }

          headerbar,
          .titlebar {
            background-color: @headerbar_bg_color;
            color: @headerbar_fg_color;
            border-color: @headerbar_border_color;
          }

          button,
          buttonbox button,
          messagedialog button,
          window.dialog button {
            background-image: none;
            background-color: ${colors.bgLight};
            color: @window_fg_color;
            border-color: ${colors.bgLight};
            box-shadow: none;
          }

          button:hover,
          buttonbox button:hover,
          messagedialog button:hover,
          window.dialog button:hover {
            background-image: none;
            background-color: ${colors.bgLight};
            color: @window_fg_color;
            border-color: ${colors.fgDark};
            box-shadow: none;
          }

          button:active,
          button:checked,
          buttonbox button:active,
          messagedialog button:active,
          window.dialog button:active {
            background-image: none;
            background-color: ${colors.bgLight};
            color: @window_fg_color;
            border-color: ${colors.fgDark};
            box-shadow: none;
          }

          messagedialog,
          messagedialog.background,
          messagedialog headerbar,
          messagedialog .titlebar,
          messagedialog box,
          messagedialog grid,
          window.dialog,
          window.dialog .background,
          window.dialog headerbar,
          window.dialog .titlebar {
            background-color: @dialog_bg_color;
            color: @dialog_fg_color;
            border-color: @dialog_bg_color;
          }

          messagedialog label,
          window.dialog label {
            color: @dialog_fg_color;
          }

          row:hover {
            background-color: ${colors.bgLight};
          }

          row:selected,
          list row:selected,
          treeview:selected {
            background-color: ${colors.bgLight};
            color: @window_fg_color;
          }

          filechooser headerbar,
          filechooser .titlebar {
            background-color: @window_bg_color;
            color: @window_fg_color;
            border-color: @window_bg_color;
          }

          filechooser #pathbarbox button:checked,
          filechooser #pathbarbox button:checked:hover,
          filechooser #pathbarbox button:checked:active,
          filechooser #pathbarbox menubutton > button:checked,
          filechooser #pathbarbox menubutton > button:checked:hover,
          filechooser #pathbarbox menubutton > button:checked:active {
            background-image: none;
            background-color: @window_bg_color;
            color: @window_fg_color;
            border-color: @window_bg_color;
            box-shadow: none;
            outline: none;
          }

          treeview.view header button,
          treeview.view header button:hover,
          treeview.view header button:active {
            background-image: none;
            background-color: @view_bg_color;
            color: @window_fg_color;
            border-color: @view_bg_color;
            box-shadow: none;
          }

          headerbar button.image-button,
          toolbar button.image-button,
          .toolbar button.image-button {
            background-image: none;
            background-color: transparent;
            border-color: transparent;
            box-shadow: none;
          }

          headerbar entry,
          headerbar entry:backdrop,
          headerbar .location,
          headerbar .location:backdrop,
          headerbar .path-bar,
          headerbar .path-bar:backdrop,
          headerbar .pathbar,
          headerbar .pathbar:backdrop,
          headerbar pathbar,
          headerbar pathbar:backdrop,
          headerbar .path-bar button,
          headerbar .path-bar button:backdrop,
          headerbar .pathbar button,
          headerbar .pathbar button:backdrop,
          headerbar pathbar button,
          headerbar pathbar button:backdrop,
          headerbar button.path-bar-button,
          headerbar button.path-bar-button:backdrop,
          headerbar button.pathbarbutton,
          headerbar button.pathbarbutton:backdrop {
            background-image: none;
            background-color: ${colors.bgLight};
            color: @window_fg_color;
            border-color: ${colors.fgDark};
            box-shadow: none;
          }

          decoration { border-radius: 0; }
          paned > separator { background-image: image(transparent); }
          paned > separator:backdrop { background-image: image(transparent); }
        '';
        gtk4.extraCss = ''
          @define-color accent_color          ${colors.bg};
          @define-color accent_bg_color       ${colors.bg};
          @define-color accent_fg_color       ${colors.bg};
          @define-color destructive_color     ${colors.red};
          @define-color destructive_bg_color  ${colors.red};
          @define-color destructive_fg_color  ${colors.bg};
          @define-color success_color         ${colors.green};
          @define-color success_bg_color      ${colors.green};
          @define-color warning_color         ${colors.yellow};
          @define-color warning_bg_color      ${colors.yellow};
          @define-color error_color           ${colors.red};
          @define-color error_bg_color        ${colors.red};
          @define-color window_bg_color       ${colors.bg};
          @define-color window_fg_color       ${colors.fg};
          @define-color view_bg_color         ${colors.bg};
          @define-color view_fg_color         ${colors.fg};
          @define-color headerbar_bg_color    ${colors.bg};
          @define-color headerbar_fg_color    ${colors.fg};
          @define-color headerbar_border_color ${colors.bg};
          @define-color headerbar_backdrop_color ${colors.bg};
          @define-color sidebar_bg_color      ${colors.bg};
          @define-color sidebar_fg_color      ${colors.fgDark};
          @define-color sidebar_backdrop_color ${colors.bg};
          @define-color card_bg_color         ${colors.bg};
          @define-color card_fg_color         ${colors.fg};
          @define-color popover_bg_color      ${colors.bg};
          @define-color popover_fg_color      ${colors.fg};
          @define-color dialog_bg_color       ${colors.bg};
          @define-color dialog_fg_color       ${colors.fg};

          window,
          dialog,
          popover,
          menu,
          .background {
            background-color: @window_bg_color;
            color: @window_fg_color;
          }

          view,
          .view,
          list,
          gridview,
          columnview,
          textview text,
          viewport,
          scrolledwindow {
            background-color: @view_bg_color;
            color: @view_fg_color;
          }

          headerbar,
          .titlebar {
            background-color: @headerbar_bg_color;
            color: @headerbar_fg_color;
            border-color: @headerbar_border_color;
          }

          navigation-view,
          navigation-sidebar,
          sidebar,
          .sidebar {
            background-color: @sidebar_bg_color;
            color: @sidebar_fg_color;
          }

          button,
          buttonbox button,
          messagedialog button,
          window.dialog button {
            background-image: none;
            background-color: ${colors.bgLight};
            color: @window_fg_color;
            border-color: ${colors.bgLight};
            box-shadow: none;
          }

          button:hover,
          buttonbox button:hover,
          messagedialog button:hover,
          window.dialog button:hover {
            background-image: none;
            background-color: ${colors.bgLight};
            color: @window_fg_color;
            border-color: ${colors.fgDark};
            box-shadow: none;
          }

          button:active,
          button:checked,
          buttonbox button:active,
          messagedialog button:active,
          window.dialog button:active {
            background-image: none;
            background-color: ${colors.bgLight};
            color: @window_fg_color;
            border-color: ${colors.fgDark};
            box-shadow: none;
          }

          messagedialog,
          messagedialog.background,
          messagedialog headerbar,
          messagedialog .titlebar,
          messagedialog box,
          messagedialog grid,
          window.dialog,
          window.dialog .background,
          window.dialog headerbar,
          window.dialog .titlebar {
            background-color: @dialog_bg_color;
            color: @dialog_fg_color;
            border-color: @dialog_bg_color;
          }

          messagedialog label,
          window.dialog label {
            color: @dialog_fg_color;
          }

          row:hover {
            background-color: ${colors.bgLight};
          }

          row:selected,
          list row:selected,
          gridview child:selected {
            background-color: ${colors.bgLight};
            color: @window_fg_color;
          }

          /* Nautilus trash/utility banners. AdwBanner's CSS node is `banner`. */
          window.view banner > revealer > widget,
          banner > revealer > widget,
          toolbar,
          .toolbar,
          actionbar,
          infobar {
            background-color: @view_bg_color;
            color: @view_fg_color;
            border-color: @view_bg_color;
          }

          window.view banner > revealer > widget:backdrop,
          banner > revealer > widget:backdrop {
            background-color: @view_bg_color;
          }

          window.view banner button,
          banner button,
          toolbar button,
          .toolbar button,
          actionbar button,
          infobar button {
            background-color: @card_bg_color;
            color: @card_fg_color;
          }

          window.view banner button:hover,
          banner button:hover,
          toolbar button:hover,
          .toolbar button:hover,
          actionbar button:hover,
          infobar button:hover {
            background-color: ${colors.bgLight};
          }

          /* Nautilus/file-picker polish. Keep header/tool bars visually flat and
             use normal bg for column headers like Name/Size/Modified. */
          headerbar,
          headerbar windowhandle,
          headerbar box,
          toolbar,
          .toolbar,
          filechooserwidget headerbar,
          filechooserwidget .titlebar {
            background-color: @window_bg_color;
            color: @window_fg_color;
            border-color: @window_bg_color;
          }

          filechooser #pathbarbox button:checked,
          filechooser #pathbarbox button:checked:hover,
          filechooser #pathbarbox button:checked:active,
          filechooser #pathbarbox menubutton > button:checked,
          filechooser #pathbarbox menubutton > button:checked:hover,
          filechooser #pathbarbox menubutton > button:checked:active,
          filechooserwidget #pathbarbox button:checked,
          filechooserwidget #pathbarbox button:checked:hover,
          filechooserwidget #pathbarbox button:checked:active,
          filechooserwidget #pathbarbox menubutton > button:checked,
          filechooserwidget #pathbarbox menubutton > button:checked:hover,
          filechooserwidget #pathbarbox menubutton > button:checked:active {
            background-image: none;
            background-color: @window_bg_color;
            color: @window_fg_color;
            border-color: @window_bg_color;
            box-shadow: none;
            outline: none;
          }

          headerbar button,
          toolbar button,
          .toolbar button {
            background-image: none;
            background-color: transparent;
            color: @window_fg_color;
            border-color: transparent;
            box-shadow: none;
          }

          headerbar button.image-button,
          toolbar button.image-button,
          .toolbar button.image-button {
            background-image: none;
            background-color: transparent;
            border-color: transparent;
            box-shadow: none;
          }

          headerbar entry,
          headerbar entry:backdrop,
          headerbar .location,
          headerbar .location:backdrop,
          headerbar .path-bar,
          headerbar .path-bar:backdrop,
          headerbar .pathbar,
          headerbar .pathbar:backdrop,
          headerbar pathbar,
          headerbar pathbar:backdrop,
          headerbar .path-bar button,
          headerbar .path-bar button:backdrop,
          headerbar .pathbar button,
          headerbar .pathbar button:backdrop,
          headerbar pathbar button,
          headerbar pathbar button:backdrop,
          headerbar button.path-bar-button,
          headerbar button.path-bar-button:backdrop,
          headerbar button.pathbarbutton,
          headerbar button.pathbarbutton:backdrop {
            background-image: none;
            background-color: ${colors.bgLight};
            color: @window_fg_color;
            border-color: ${colors.fgDark};
            box-shadow: none;
          }

          headerbar button:hover,
          toolbar button:hover,
          .toolbar button:hover {
            background-image: none;
            background-color: ${colors.bgLight};
            color: @window_fg_color;
            border-color: transparent;
            box-shadow: none;
          }

          columnview header,
          columnview header button,
          columnview column header,
          columnview column header button,
          listview header,
          listview header button {
            background-image: none;
            background-color: @view_bg_color;
            color: @window_fg_color;
            border-color: @view_bg_color;
            box-shadow: none;
          }

        '';
      };

      xdg.dataFile = {
        "icons/Nos/index.theme".text = ''
          [Icon Theme]
          Name=Nos
          Comment=Theme-aware folder icons with Adwaita fallback
          Inherits=Adwaita,hicolor
          Directories=scalable/places

          [scalable/places]
          Size=64
          MinSize=16
          MaxSize=512
          Type=Scalable
          Context=Places
        '';
      }
      // builtins.listToAttrs (
        map (name: {
          name = "icons/Nos/scalable/places/${name}.svg";
          value.text = folderSvg;
        }) folderIconNames
      );

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = "adw-gtk3-dark";
          icon-theme = "Nos";
          font-name = "${font.system} ${toString font.size}";
          document-font-name = "${font.system} ${toString font.size}";
          monospace-font-name = "${font.mono} ${toString font.monoSize}";
        };

        # Keep Nautilus and GTK file pickers using the same global ordering.
        "org/gnome/nautilus/preferences" = {
          default-sort-order = "name";
          default-sort-in-reverse-order = false;
        };

        "org/gtk/gtk4/settings/file-chooser" = {
          sort-column = "name";
          sort-order = "ascending";
          sort-directories-first = true;
        };

        "org/gtk/settings/file-chooser" = {
          sort-column = "name";
          sort-order = "ascending";
          sort-directories-first = true;
        };
      };
    };
}
