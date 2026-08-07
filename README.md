# NixOS and Home Manager configuration

Target platform: x86_64 Linux. `hosts/legion` remains machine-specific; Home Manager profile does not.

## Use on another Linux distribution

Import this flake and create a host output with `lib.mkHomeConfiguration`:

```nix
{
  inputs.nos.url = "github:OWNER/REPOSITORY";

  outputs = { self, nos, ... }: {
    homeConfigurations.alice = nos.lib.mkHomeConfiguration {
      system = "x86_64-linux";
      username = "alice";
      homeDirectory = "/home/alice";
      stateVersion = "26.05";
      flakeDirectory = "/home/alice/NixOS"; # optional; enables repo helper commands
    };
  };
}
```

Then run:

```bash
home-manager switch --flake .#alice
```

`targets.genericLinux` and user-level XDG portals enable automatically outside NixOS. Distro must provide working user systemd session. Docker/KVM features still require Docker daemon, Compose support, and `/dev/kvm` from host distro.

Other flakes may import `homeManagerModules.default` directly instead. Set `home.username`, `home.homeDirectory`, and `home.stateVersion` in caller.
