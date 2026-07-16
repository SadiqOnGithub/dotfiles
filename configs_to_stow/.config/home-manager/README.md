# Home Manager

Personal Home Manager configuration using Nix flakes.

## Setup

```bash
home-manager switch --flake .
```

## What's configured

- **Packages**: `eza`, `bat`
- **Home Manager**: enabled as a Nix module

## Usage

| Command | Description |
|---------|-------------|
| `home-manager switch` | Apply configuration |
| `home-manager rollback` | Revert to previous generation |
| `nix run home-manager/master -- switch --flake .` | Update and apply |

## Common Nix Commands

### Profiles

| Command | Description |
|---------|-------------|
| `nix profile list` | List installed packages |
| `nix profile install nixpkgs#<pkg>` | Install a package |
| `nix profile add nixpkgs#<pkg>` | Add package to profile |
| `nix profile remove <pkg>` | Remove a package |

### Flake & Store

| Command | Description |
|---------|-------------|
| `nix flake --help` | Flake help |
| `nix store gc` | Garbage collect store |
| `nix search nixpkgs <pkg>` | Search for packages |
| `nix shell nixpkgs#<pkg>` | Run package temporarily |
| `nix repl` | Start Nix REPL |
