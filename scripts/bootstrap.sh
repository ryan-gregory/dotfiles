#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"
cd "$DOTFILES"

echo "==> Installing Nix environment..."
nix profile install .

echo "==> Stowing configs..."
cd stow

# Remove existing targets that would conflict
for pkg in zsh ghostty nvim herdr pi markdownlint; do
  stow --adopt -t "$HOME" "$pkg" 2>/dev/null || true
done

# Now restow to ensure symlinks point at our dotfiles
for pkg in zsh ghostty nvim herdr pi markdownlint; do
  stow -R -t "$HOME" "$pkg"
done

echo "==> Setting up Rust toolchain..."
rustup default stable 2>/dev/null || true

echo "==> Installing dotnet global tools..."
dotnet tool install --global EasyDotnet 2>/dev/null || true
dotnet tool install --global dotnet-ef 2>/dev/null || true

echo "==> Installing pi..."
if ! command -v pi &>/dev/null; then
  yarn global add @earendil-works/pi-coding-agent
fi

echo "==> Done. Open a new shell."
