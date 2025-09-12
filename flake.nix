{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.url = "github:hraban/mac-app-util";
      # NEW:
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-services = {
      url = "github:homebrew/homebrew-services";
      flake = false;
    };
    # Aerospace Homebrew tap for installing the app via cask
    aerospace-tap = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, mac-app-util, home-manager, nix-homebrew, homebrew-core, homebrew-cask, homebrew-bundle, homebrew-services, aerospace-tap, ... }:
  let
    configuration = { pkgs, lib, ... }: {
      nixpkgs.config.allowUnfree = true;
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = [
        pkgs.git
        pkgs.vim
        pkgs.neovim
        pkgs.obsidian
        pkgs.vscode
        pkgs.wget
	pkgs.ghostty-bin
	pkgs.neofetch
	pkgs.uv
	pkgs.nodejs_22
    pkgs.python3
    pkgs.python3Packages.jupytext
    pkgs.fd
        # Codex CLI (scoped npm package via nodePackages_latest)
        pkgs.nodePackages_latest.openai__codex
      ];

      nixpkgs.config.allowBroken = true;


      homebrew = {
        enable = true;
        taps = [
          "nikitabobko/tap"
        ];

        # Uncomment to install cli packages from Homebrew.
        brews = [
           "mas"
        ];

        # Uncomment to install cask packages from Homebrew.
        casks = [
           "zoom"
           "inkscape"
           "karabiner-elements"
           "unnaturalscrollwheels"
           "font-jetbrains-mono"
           "font-jetbrains-mono-nerd-font"
           # Aerospace temporarily disabled (was: "nikitabobko/tap/aerospace")
        ];

        # Uncomment to install app store apps using mas-cli.
        masApps = {
           "Microsoft Word"       = 462054704;
           "Microsoft Excel"      = 462058435;
           "Microsoft PowerPoint" = 462062816;
           "Microsoft OneNote"    = 784801555;
           "OneDrive"             = 823766827;   # optional
        };

        # Uncomment to automatically update Homebrew and upgrade packages.
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };
      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;
      programs.zsh.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
      system.primaryUser = "manug";

      system.defaults = {
        dock.autohide  = true;
	dock.persistent-apps = [
        	"${pkgs.ghostty-bin}/Applications/Ghostty.app"
		"/Applications/Google Chrome.app"
		"${pkgs.obsidian}/Applications/Obsidian.app"
		"/System/Applications/Mail.app"
		"/System/Applications/Calendar.app"
	];
        dock.magnification = false;
        dock.mineffect = "genie";
        finder.FXPreferredViewStyle = "clmv";
	finder.AppleShowAllFiles = true;
        finder.ShowPathbar = true;  # optional
        finder.ShowStatusBar = true; # optional
        loginwindow.GuestEnabled  = false;
        NSGlobalDomain.AppleInterfaceStyle = "Dark";
        NSGlobalDomain.KeyRepeat = 2;
	NSGlobalDomain.ApplePressAndHoldEnabled = false;
	NSGlobalDomain.InitialKeyRepeat=15;
    	NSGlobalDomain."com.apple.keyboard.fnState" = true;
        NSGlobalDomain._HIHideMenuBar = false;
      };

      # Aerospace autostart disabled (was a user LaunchAgent)
      # launchd.user.agents.aerospace = {
      #   serviceConfig = {
      #     ProgramArguments = [ "/usr/bin/open" "-a" "AeroSpace" ];
      #     RunAtLoad = true;
      #     KeepAlive = true;
      #   };
      # };

      # sketchybar removed

      # (no activation script needed for Homebrew taps; taps are mutable)
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        mac-app-util.darwinModules.default
        nix-homebrew.darwinModules.nix-homebrew
	home-manager.darwinModules.home-manager
        {
	  system.primaryUser = "manug";

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;


	  home-manager.backupFileExtension = "hm-backup";

	  # Your HM config for user manug goes here:
          home-manager.users."manug" = { pkgs, lib, config, ... }: {
              # Required on macOS:
              home.username = "manug";
              home.homeDirectory = lib.mkForce "/Users/manug";
              home.stateVersion = "24.11";  # lock HM state (pick your HM version)


              # Example: write Karabiner config declaratively
              xdg.configFile."karabiner/karabiner.json".source = ./dotfiles/karabiner/karabiner.json;
              xdg.configFile."karabiner/karabiner.json".force = true;
              # Aerospace config
              xdg.configFile."aerospace/aerospace.toml".source = ./dotfiles/aerospace/aerospace.toml;
              xdg.configFile."aerospace/aerospace.toml".force = true;
              # sketchybar removed
              home.file.".gitconfig".source = ./dotfiles/git/.gitconfig;
              xdg.configFile."ghostty/config".source = ./dotfiles/ghostty/config;
              xdg.configFile."ghostty/themes".source = ./dotfiles/ghostty/themes;
              xdg.configFile."nvim".source = ./dotfiles/nvim;

	      programs.zsh = {
                   enable = true;

                   # Keep your existing configs, and append this snippet
                   initExtra = ''
                     # Show system info at shell start
                     if command -v neofetch >/dev/null 2>&1; then
                       neofetch
                     fi
                   '';
                 };

          };

          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "manug";

            # Optional: Declarative tap management
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "homebrew/homebrew-bundle" = homebrew-bundle;
              "homebrew/homebrew-services" = homebrew-services;
              # Needed to install Aerospace from its tap
              "nikitabobko/tap" = aerospace-tap;
            };

            # Allow imperative tap management (brew tap, brew update)
            mutableTaps = true;

            # Automatically migrate/fix existing Homebrew installations (ownership, layout)
            autoMigrate = true;
          };
        }
      ];
    };
  };
}
