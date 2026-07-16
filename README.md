# dotfiles

Portable dev environment. Nix flake for packages, GNU Stow for configs.

## What's in it

**Languages:** Node 22, Deno, .NET 10, Rust (via rustup), Python 3.14, Java (latest), Lua 5.4, Elixir/Erlang (OTP)

**Tools:** neovim, lazygit, ripgrep, fd, fzf, jq, yq, bat, delta, direnv, age, sops, azure-cli, docker-client

**Configs:** zsh (oh-my-zsh), ghostty, neovim (kickstart-based), herdr, pi (agent settings + skills), markdownlint

## Platforms

- macOS Apple Silicon (`aarch64-darwin`)
- Linux (`x86_64-linux`, `aarch64-linux`, WSL2)

## Setup

```bash
# Install Nix
sh <(curl -L https://nixos.org/nix/install) --daemon
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Clone
git clone git@github.com:ryan-gregory/dotfiles.git ~/.dotfiles

# Bootstrap
~/.dotfiles/scripts/bootstrap.sh

# Start a new shell
zsh
```

## Structure

```
flake.nix                          # all packages declared here
scripts/bootstrap.sh               # one-shot: install packages, stow configs, setup rust/pi
stow/
├── zsh/.zshrc                     # oh-my-zsh via nix store path
├── zsh/.zshenv
├── zsh/.zprofile
├── ghostty/.config/ghostty/config # catppuccin mocha, fira code
├── nvim/.config/nvim/             # kickstart + custom plugins
├── herdr/.config/herdr/config.toml
├── pi/.pi/agent/AGENTS.md         # agent rules
├── pi/.pi/agent/settings.json
├── pi/.agents/skills/             # portable skills (tdd, diagnosis, design, etc.)
└── markdownlint/.markdownlint.json
```

## Day-to-day

**Update all packages:**
```bash
cd ~/.dotfiles
nix flake update
nix profile upgrade '.*'
```

**Add a new config:**
```bash
mkdir -p stow/foo/.config/foo
# add files
cd stow && stow -t ~ foo
```

**Per-project version pinning:**

Don't version-matrix here. Projects carry their own `flake.nix` + `.envrc`:

```nix
# ~/projects/something/flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { nixpkgs, ... }: {
    devShells.x86_64-linux.default = let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in pkgs.mkShell {
      packages = [ pkgs.nodejs_20 pkgs.dotnet-sdk_8 ];
    };
  };
}
```

```bash
# ~/projects/something/.envrc
use flake
```

`cd` in, direnv activates, project versions override globals. `cd` out, back to defaults.

## Notes

- Ghostty uses XDG path (`~/.config/ghostty/config`) on all platforms
- On macOS, Ghostty itself is a .app (install via Homebrew cask or dmg — Nix can't manage GUI apps)
- `rustup` is in the flake; actual toolchains managed by rustup
- Podman for containers — daemonless, rootless, fully Nix-managed
- On macOS, use the Linux VM layer (Apple Virtual Machine framework or `podman machine`)
- oh-my-zsh lives in the Nix store, not `~/.oh-my-zsh`
