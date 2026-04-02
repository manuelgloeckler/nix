---
name: nix-darwin
description: Nix-darwin and home-manager patterns for macOS
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: nix
---

## What I do

- Guide on nix-darwin configuration patterns
- Help with home-manager dotfile management
- Provide flake.nix conventions
- Assist with package and service management

## Flake structure

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, ... }: {
    darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        home-manager.darwinModules.home-manager
        { /* home-manager config */ }
      ];
    };
  };
}
```

## System packages

```nix
environment.systemPackages = with pkgs; [
  git
  vim
  ripgrep
  fd
  jq
];
```

## Homebrew integration

```nix
homebrew = {
  enable = true;
  casks = [ "ghostty" "firefox" ];
  masApps = { "Xcode" = 497799835; };
  onActivation.autoUpdate = true;
};
```

## Dotfile management

```nix
home-manager.users."user" = {
  xdg.configFile."app/config".source = ./dotfiles/app/config;
  home.file.".gitconfig".source = ./dotfiles/git/.gitconfig;
};
```

## Useful commands

```bash
darwin-rebuild switch --flake ~/.config/nix#mac
nix flake update
nix store gc --delete-older-than 30d
```

## When to use me

Use this when configuring nix-darwin, managing homebrew, or setting up dotfiles with home-manager.
