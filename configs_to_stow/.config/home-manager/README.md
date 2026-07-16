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

## Updating nixpkgs and home-manager

The pinned versions of nixpkgs and home-manager are defined in `flake.nix` and locked in `flake.lock`. To update them:

### Quick update (latest commit on current release branch)

```bash
nix flake update
home-manager switch --flake .
```

This updates `flake.lock` to the latest commits of `nixos-25.05` and `release-25.05` without changing branch names in `flake.nix`.

### Upgrade to a new release

1. Edit `flake.nix` and change the branch names:
   - `nixpkgs`: update the `ref` (e.g., `nixos-25.05` → `nixos-25.11`)
   - `home-manager`: update the `ref` (e.g., `release-25.05` → `release-25.11`)

2. Update the lock file and apply:
   ```bash
   nix flake update
   home-manager switch --flake .
   ```

### Pinning a specific revision

To pin nixpkgs or home-manager to a specific commit:

1. Edit `flake.nix` and add `rev` to the input:
   ```nix
   nixpkgs.url = "github:NixOS/nixpkgs/<branch>?rev=<commit-hash>";
   ```

2. Update the lock file and apply:
   ```bash
   nix flake update
   home-manager switch --flake .
   ```
