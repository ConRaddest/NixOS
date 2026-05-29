{ font, ... }:

{
  programs.kitty = {
    enable = true;
    settings = {
      font_family = font.mono;
      font_size = font.monoSize;
      window_padding_width = 8;
      confirm_os_window_close = 0;
      enable_audio_bell = false;
    };
  };
}
