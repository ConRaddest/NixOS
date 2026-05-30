{ colors, ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = {
      ls  = "eza --icons";
      ll  = "eza -la --icons";
      cd  = "z";

      # NixOS management
      nos-refresh = "home-manager switch --flake $HOME/OS#$USER";
      nos-build   = "sudo nixos-rebuild switch --flake $HOME/OS#$HOSTNAME";
      nos-update  = "nix flake update --flake $HOME/OS && sudo nixos-rebuild switch --flake $HOME/OS#$HOSTNAME";
      nos-check   = "sudo nixos-rebuild dry-run --flake $HOME/OS#$HOSTNAME";
    };
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;

    settings = {
      add_newline = false;
      format = "$directory$git_branch$character";

      character = {
        success_symbol = "[❯](${colors.blue})";
        error_symbol = "[❯](${colors.red})";
      };

      directory = {
        style = "${colors.blue}";
        truncation_length = 3;
        truncate_to_repo = false;
        format = "[$path]($style) ";
      };

      git_branch = { 
        symbol = "";
        style = "${colors.blue}";
        format = "[$symbol$branch]($style) ";
      };
    };
  };
}
