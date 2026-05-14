{
  description = "Nix configs for macOS and Linux server environments";

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
        github-mcp-server
        lazygit 
        vim neovim 
        tree-sitter 
        fd 
        ripgrep 
        jq 
        imagemagick
        imagemagick.dev   # ships MagickWand.pc — needed for the magick LuaRock that image.nvim builds against
        pkg-config
        obsidian 
        vscode 
        wget 
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
        opencode
        claude-code
        texpresso   # live LaTeX renderer; pairs with let-def/texpresso.vim in nvim
        tectonic    # single-binary TeX engine texpresso uses to actually compile (no system TeX needed)
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

        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            "36" = { enabled = false; }; # Disable F11 "Show Desktop"
          };
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
          "tgpt"
          # Helpful extras
          # WM stack
          "FelixKratz/formulae/borders"
        ];

        casks = [
          "zoom"
          "inkscape"
          "karabiner-elements"
          "linearmouse"
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
          # New MAS needs sudo... not compatible
          #"Microsoft Word" = 462054704;
          #"Microsoft Excel" = 462058435;
          #"Microsoft PowerPoint" = 462062816;
          #"Microsoft OneNote" = 784801555;
          #"OneDrive" = 823766827;
          #"Highlights" = 1498912833;
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

    linuxServerHomeModule = { pkgs, lib, ... }: {
      home = {
        username = "manug";
        homeDirectory = "/home/manug";
        stateVersion = "24.11";
      };

      targets.genericLinux.enable = true;
      programs.home-manager.enable = true;

      home.packages = with pkgs; [
        git
        gh
        github-mcp-server
        lazygit
        vim
        neovim
        tree-sitter
        fd
        ripgrep
        jq
        imagemagick
        imagemagick.dev   # ships MagickWand.pc — needed for the magick LuaRock that image.nvim builds against
        pkg-config
        wget
        fastfetch
        uv
        nodejs_22
        python3
        python3Packages.jupytext
        ghostscript
        cargo
        ffmpeg
        opencode
        claude-code
        texpresso   # live LaTeX renderer; pairs with let-def/texpresso.vim in nvim
        texlive.combined.scheme-medium   # Linux box has no basictex, give texpresso a real TeX install
      ];

      home.file.".gitconfig".source = ./dotfiles/git/.gitconfig;
      xdg.configFile."nvim".source = ./dotfiles/nvim;
      xdg.configFile."lazygit/config.yml".source = ./dotfiles/lazygit/config.yml;

      xdg.configFile."opencode/opencode.json".source = ./dotfiles/opencode/opencode.json;
      xdg.configFile."opencode/system-prompt.md".source = ./dotfiles/opencode/system-prompt.md;
      xdg.configFile."opencode/skills".source = ./dotfiles/opencode/skills;
      xdg.configFile."opencode/themes".source = ./dotfiles/opencode/themes;

      home.file.".claude/CLAUDE.md".source = ./dotfiles/claude/CLAUDE.md;

      home.activation.claudeCodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        settings_json="$HOME/.claude/settings.json"
        claude_json="$HOME/.claude.json"
        tmp="$(${pkgs.coreutils}/bin/mktemp)"
        mkdir -p "$HOME/.claude"

        if [ ! -f "$settings_json" ]; then
          printf '{}\n' > "$settings_json"
        fi

        if ${pkgs.jq}/bin/jq --slurpfile settings ${./dotfiles/claude/settings.json} '
          .enableAllProjectMcpServers = $settings[0].enableAllProjectMcpServers |
          .permissions = (.permissions // {}) |
          .permissions.defaultMode = $settings[0].permissions.defaultMode |
          .permissions.additionalDirectories = (((.permissions.additionalDirectories // []) + ($settings[0].permissions.additionalDirectories // [])) | unique) |
          .permissions.allow = (((.permissions.allow // []) + ($settings[0].permissions.allow // [])) | unique) |
          .permissions.deny = $settings[0].permissions.deny |
          .env = ((.env // {}) * ($settings[0].env // {}))
        ' "$settings_json" > "$tmp"; then
          mv "$tmp" "$settings_json"
        else
          rm -f "$tmp"
          echo "Skipping Claude Code settings merge: $settings_json is not valid JSON" >&2
        fi

        tmp="$(${pkgs.coreutils}/bin/mktemp)"

        if [ ! -f "$claude_json" ]; then
          printf '{}\n' > "$claude_json"
        fi

        if ${pkgs.jq}/bin/jq --slurpfile mcp ${./dotfiles/claude/mcp.json} '
          .mcpServers = ((.mcpServers // {}) * ($mcp[0].mcpServers // {}))
        ' "$claude_json" > "$tmp"; then
          mv "$tmp" "$claude_json"
        else
          rm -f "$tmp"
          echo "Skipping Claude Code MCP merge: $claude_json is not valid JSON" >&2
        fi
      '';

      home.activation.openagents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if ! command -v openagents >/dev/null 2>&1 && [ ! -f "$HOME/.openagents/nodejs/node_modules/.bin/openagents" ]; then
          echo "Installing OpenAgents..."
          curl -fsSL https://openagents.org/install.sh | bash 2>/dev/null || true
        fi
      '';

      programs.zsh = {
        enable = true;
        initContent = ''
          # OpenAgents PATH
          export PATH="$HOME/.openagents/nodejs/node_modules/.bin:$PATH"

          # UV tools PATH
          export PATH="$HOME/.local/bin:$PATH"

          # GitHub MCP auth from gh CLI
          if command -v gh >/dev/null 2>&1; then
            _gh_pat="$(gh auth token 2>/dev/null || true)"
            if [ -n "$_gh_pat" ]; then
              export GITHUB_PAT="$_gh_pat"
            fi
            unset _gh_pat
          fi
        '';
      };
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

              # OpenCode config
              xdg.configFile."opencode/opencode.json".source = ./dotfiles/opencode/opencode.json;
              xdg.configFile."opencode/system-prompt.md".source = ./dotfiles/opencode/system-prompt.md;
              xdg.configFile."opencode/skills".source = ./dotfiles/opencode/skills;
              xdg.configFile."opencode/themes".source = ./dotfiles/opencode/themes;

              # Claude Code config
              home.file.".claude/CLAUDE.md".source = ./dotfiles/claude/CLAUDE.md;

              home.activation.claudeCodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                settings_json="$HOME/.claude/settings.json"
                claude_json="$HOME/.claude.json"
                tmp="$(${pkgs.coreutils}/bin/mktemp)"
                mkdir -p "$HOME/.claude"

                if [ ! -f "$settings_json" ]; then
                  printf '{}\n' > "$settings_json"
                fi

                if ${pkgs.jq}/bin/jq --slurpfile settings ${./dotfiles/claude/settings.json} '
                  .enableAllProjectMcpServers = $settings[0].enableAllProjectMcpServers |
                  .permissions = (.permissions // {}) |
                  .permissions.defaultMode = $settings[0].permissions.defaultMode |
                  .permissions.additionalDirectories = (((.permissions.additionalDirectories // []) + ($settings[0].permissions.additionalDirectories // [])) | unique) |
                  .permissions.allow = (((.permissions.allow // []) + ($settings[0].permissions.allow // [])) | unique) |
                  .permissions.deny = $settings[0].permissions.deny |
                  .env = ((.env // {}) * ($settings[0].env // {}))
                ' "$settings_json" > "$tmp"; then
                  mv "$tmp" "$settings_json"
                else
                  rm -f "$tmp"
                  echo "Skipping Claude Code settings merge: $settings_json is not valid JSON" >&2
                fi

                tmp="$(${pkgs.coreutils}/bin/mktemp)"

                if [ ! -f "$claude_json" ]; then
                  printf '{}\n' > "$claude_json"
                fi

                if ${pkgs.jq}/bin/jq --slurpfile mcp ${./dotfiles/claude/mcp.json} '
                  .mcpServers = ((.mcpServers // {}) * ($mcp[0].mcpServers // {}))
                ' "$claude_json" > "$tmp"; then
                  mv "$tmp" "$claude_json"
                else
                  rm -f "$tmp"
                  echo "Skipping Claude Code MCP merge: $claude_json is not valid JSON" >&2
                fi
              '';

              home.activation.openagents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                if ! command -v openagents >/dev/null 2>&1 && [ ! -f "$HOME/.openagents/nodejs/node_modules/.bin/openagents" ]; then
                  echo "Installing OpenAgents..."
                  curl -fsSL https://openagents.org/install.sh | bash 2>/dev/null || true
                fi
              '';

              programs.zsh = {
                enable = true;
                initContent = ''
                  # OpenAgents PATH
                  export PATH="$HOME/.openagents/nodejs/node_modules/.bin:$PATH"

                  # UV tools PATH
                  export PATH="$HOME/.local/bin:$PATH"

                  # GitHub MCP auth from gh CLI
                  if command -v gh >/dev/null 2>&1; then
                    _gh_pat="$(gh auth token 2>/dev/null || true)"
                    if [ -n "$_gh_pat" ]; then
                      export GITHUB_PAT="$_gh_pat"
                    fi
                    unset _gh_pat
                  fi

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

    # Build with: home-manager switch --flake .#linux-server
    homeConfigurations."linux-server" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config = {
          allowUnfree = true;
          allowBroken = false;
        };
      };

      modules = [
        linuxServerHomeModule
      ];
    };
  };
}
