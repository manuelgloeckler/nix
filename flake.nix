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

  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, mac-app-util, home-manager, nix-homebrew,
                     homebrew-core, homebrew-cask, homebrew-bundle, homebrew-services,
                     felixkratz-formulae, ... }:
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
        git
        gh 
        lazygit 
        vim neovim 
        tree-sitter 
        fd 
        ripgrep 
        jq 
        imagemagick
        obsidian 
        vscode 
        wget 
        neofetch 
        fastfetch
        uv 
        nodejs_22 
        python3 
        python3Packages.jupytext 
        ghostscript
        cargo 
        lowfi
        ffmpeg 
        macmon 
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
          AppleInterfaceStyleSwitchesAutomatically = false;
          KeyRepeat = 2;
          ApplePressAndHoldEnabled = false;
          InitialKeyRepeat = 15;
          "com.apple.keyboard.fnState" = true;
        };
        spaces.spans-displays = false; # Separate Spaces per display (for yabai)
      };

      system.defaults.CustomUserPreferences = {
        NSGlobalDomain = {
          NSWindowResizeTime = 0.001;
          NSAutomaticWindowAnimationsEnabled = false;
        };

        "com.apple.dock" = {
          expose-animation-duration = 0.1;
        };

        "com.apple.universalaccess" = {
          reduceMotion = true;
        };
      };

      # Use custom launchd agents instead of nix-darwin services or brew services
      #services.yabai.enable = lib.mkForce false;
      #services.skhd.enable = lib.mkForce false;

      ## Launch WM components via launchd (user agents)
      #launchd.user.agents.borders = {
      #  serviceConfig = {
      #    ProgramArguments = [ "/opt/homebrew/bin/borders" ];
      #    RunAtLoad = true;
      #    KeepAlive = true;
      #  };
      #};

      # Homebrew declarative management
      homebrew = {
        enable = true;

        taps = [
          "FelixKratz/formulae"
        ];

        brews = [
          "mas"
          "lua"
          "switchaudio-osx"
          "nowplaying-cli"
          # Helpful extras
          # WM stack
          "FelixKratz/formulae/borders"
        ];

        casks = [
          "zoom"
          "inkscape"
          "karabiner-elements"
          "unnaturalscrollwheels"
          "raycast"
          "rectangle"
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
              "felixkratz/formulae" = felixkratz-formulae;
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

              home.activation.rectangleShortcuts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                # Quit Rectangle so it reloads prefs
                /usr/bin/killall Rectangle >/dev/null 2>&1 || true

                # Ctrl+Opt+Cmd + Right Arrow => Next Display
                /usr/bin/defaults write com.knollsoft.Rectangle nextDisplay -dict \
                  keyCode -int 124 \
                  modifierFlags -int 1835008

                # Ctrl+Opt+Cmd + Left Arrow => Previous Display
                /usr/bin/defaults write com.knollsoft.Rectangle previousDisplay -dict \
                  keyCode -int 123 \
                  modifierFlags -int 1835008

                # Optional: start Rectangle at login
                /usr/bin/defaults write com.knollsoft.Rectangle launchOnLogin -bool true

                # Restart
                /usr/bin/open -gja Rectangle
              '';

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
              # yabai/skhd disabled and not linked

              # Lazygit config
              xdg.configFile."lazygit/config.yml".source = ./dotfiles/lazygit/config.yml;

              programs.zsh = {
                enable = true;
                initContent = ''
                  # Show system info at shell start
                  if command -v fastfetch >/dev/null 2>&1; then
                      fastfetch
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
