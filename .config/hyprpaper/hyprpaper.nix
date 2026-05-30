{ ... }:

let
  wallpaper = "/home/cdt/OS/.config/wallpapers/deer-sunset.png";
in
{
  services.hyprpaper = {
    enable = true;
    
    settings = {
      splash = false;
      
      preload = [
        wallpaper
      ];

      wallpaper = [
        {
          monitor = ""; # Empty string applies to all monitors
          path = wallpaper;
          fit_mode = "cover";
        }
      ];
    };
  };
}
