{
  description = "Example nix-darwin system flake (fixed)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Optional: Declarative tap management
    homebrew-core = { url = "github:homebrew/homebrew-core"; flake = false; };
    homebrew-cask = { url = "github:Homebrew/homebrew-cask"; flake = false; };
    homebrew-bundle = { url = "github:homebrew/homebrew-bundle"; flake = false; };
    homebrew-services = { url = "github:homebrew/homebrew-services"; flake = false; };

    # Additional taps for formulae used below
    felixkratz-formulae = { url = "github:FelixKratz/homebrew-formulae"; flake = false; };
    koekeishiya-formulae = { url = "github:koekeishiya/homebrew-formulae"; flake = false; };

    # Aerospace Homebrew tap (kept for later if needed)
    aerospace-tap = { url = "github:nikitabobko/homebrew-tap"; flake = false; };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, mac-app-util, home-manager, nix-homebrew,
                     homebrew-core, homebrew-cask, homebrew-bundle, homebrew-services,
                     aerospace-tap, felixkratz-formulae, koekeishiya-formulae, ... }:
  let
    configuration = { pkgs, lib, ... }: {
      nixpkgs = {
        hostPlatform = "aarch64-darwin";
        config = {
          allowUnfree = true;
          # Avoid surprising breakages
          allowBroken = false;
        };
      };

      # Base packages
      environment.systemPackages = with pkgs; [
        git gh lazygit vim neovim tree-sitter fd ripgrep jq imagemagick
        obsidian vscode wget neofetch uv nodejs_22 python3 python3Packages.jupytext ghostscript
      ];

      # Enable flakes & nix-command
      nix.settings.experimental-features = [ "nix-command" "flakes" ];

      # Shells
      programs.zsh.enable = true;

      # macOS defaults
      system.defaults = {
        dock = {
          autohide = true;
          persistent-apps = [
            "/Applications/Ghostty.app"
            "/Applications/Google Chrome.app"
            "/System/Applications/Mail.app"
            "/System/Applications/Calendar.app"
          ];
          magnification = false;
          mineffect = "genie";
          mru-spaces = false; # Do not rearrange Spaces
        };
        finder = {
          FXPreferredViewStyle = "clmv";
          CreateDesktop = false; # Hide desktop icons
          AppleShowAllFiles = true;
          ShowPathbar = true;
          ShowStatusBar = true;
        };
        loginwindow.GuestEnabled = false;
        NSGlobalDomain = {
          AppleInterfaceStyle = "Dark";
          KeyRepeat = 2;
          ApplePressAndHoldEnabled = false;
          InitialKeyRepeat = 15;
          "com.apple.keyboard.fnState" = true;
          _HIHideMenuBar = false; # Show macOS menu bar
        };
        spaces.spans-displays = false; # Separate Spaces per display (for yabai)
      };

      # Use custom launchd agents instead of nix-darwin services or brew services
      services.yabai.enable = lib.mkForce false;
      services.skhd.enable = lib.mkForce false;

      # Launch WM components via launchd (user agents)
      launchd.user.agents.yabai = {
        serviceConfig = {
          ProgramArguments = [ "/opt/homebrew/bin/yabai" ];
          RunAtLoad = true;
          KeepAlive = true;
        };
      };
      launchd.user.agents.borders = {
        serviceConfig = {
          ProgramArguments = [ "/opt/homebrew/bin/borders" ];
          RunAtLoad = true;
          KeepAlive = true;
        };
      };

      # Homebrew declarative management
      homebrew = {
        enable = true;

        taps = [
          "FelixKratz/formulae"
          "koekeishiya/formulae"
        ];

        brews = [
          "mas"
          "lua"
          "switchaudio-osx"
          "nowplaying-cli"
          # Helpful extras
          # WM stack
          "koekeishiya/formulae/yabai"
          "koekeishiya/formulae/skhd"
          "FelixKratz/formulae/borders"
        ];

        casks = [
          "zoom"
          "inkscape"
          "karabiner-elements"
          "unnaturalscrollwheels"
          "font-jetbrains-mono"
          "font-jetbrains-mono-nerd-font"
          "ghostty"
          "klatexformula"
          "basictex"
          "sf-symbols"
        ];

        masApps = {
          "Microsoft Word" = 462054704;
          "Microsoft Excel" = 462058435;
          "Microsoft PowerPoint" = 462062816;
          "Microsoft OneNote" = 784801555;
          "OneDrive" = 823766827;
        };

        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

      # Version pins
      system.configurationRevision = self.rev or self.dirtyRev or null;
      # Required by recent nix-darwin: primary login user
      system.primaryUser = "manug";
      system.stateVersion = 6; # nix-darwin versioning
    };
  in
  {
    # Build with: darwin-rebuild switch --flake .#mac
    darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        mac-app-util.darwinModules.default
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        {
          # nix-homebrew bootstrap & taps
          nix-homebrew = {
            enable = true;
            enableRosetta = true;   # Apple Silicon only
            user = "manug";        # Homebrew owner
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "homebrew/homebrew-bundle" = homebrew-bundle;
              "homebrew/homebrew-services" = homebrew-services;
              "nikitabobko/tap" = aerospace-tap;
              "felixkratz/formulae" = felixkratz-formulae;
              "koekeishiya/formulae" = koekeishiya-formulae;
            };
            mutableTaps = true;
            autoMigrate = true;
          };

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-backup";
            users."manug" = { pkgs, lib, config, ... }: {
              home = {
                username = "manug";
                homeDirectory = lib.mkForce "/Users/manug";
                stateVersion = "24.11";
              };

              # dotfiles
              xdg.configFile."karabiner/karabiner.json" = {
                source = ./dotfiles/karabiner/karabiner.json;
                force = true;
              };
              home.file.".gitconfig".source = ./dotfiles/git/.gitconfig;
              xdg.configFile."ghostty/config".source = ./dotfiles/ghostty/config;
              xdg.configFile."ghostty/themes".source = ./dotfiles/ghostty/themes;
              xdg.configFile."nvim".source = ./dotfiles/nvim;

              # WM + bar configs
              home.file.".yabairc".source = ./dotfiles/yabai/yabairc;
              home.file.".skhdrc".source = ./dotfiles/skhd/skhdrc;

              # Lazygit config
              xdg.configFile."lazygit/config.yml".source = ./dotfiles/lazygit/config.yml;

              programs.zsh = {
                enable = true;
                initContent = ''
                  # Show system info at shell start
                  if command -v neofetch >/dev/null 2>&1; then
                    neofetch
                  fi
                '';
              };

              # Managed by launchd user agents defined above
            };
          };
        }
      ];
    };
  };
}
