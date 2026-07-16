export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# Oh My Zsh via Nix store
if [ -d "$HOME/.nix-profile/share/oh-my-zsh" ]; then
  export ZSH="$HOME/.nix-profile/share/oh-my-zsh"
elif [ -d "/nix/var/nix/profiles/default/share/oh-my-zsh" ]; then
  export ZSH="/nix/var/nix/profiles/default/share/oh-my-zsh"
fi

ZSH_THEME="robbyrussell"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

# Editor
export EDITOR='nvim'

# Cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# .NET global tools
export PATH="$HOME/.dotnet/tools:$PATH"

# Direnv
eval "$(direnv hook zsh)"

# macOS memory inspector
free() {
  vm_stat | awk '
    /page size of/ {gsub("\\.","",$8); ps=$8}
    /Pages free:/ {gsub("\\.","",$3); free=$3}
    /Pages active:/ {gsub("\\.","",$3); active=$3}
    /Pages inactive:/ {gsub("\\.","",$3); inactive=$3}
    /Pages speculative:/ {gsub("\\.","",$3); speculative=$3}
    /Pages wired down:/ {gsub("\\.","",$4); wired=$4}
    /Pages occupied by compressor:/ {gsub("\\.","",$5); compressed=$5}
    END {
      cmd = "sysctl -n hw.memsize"; cmd | getline total; close(cmd)
      used = (active + wired + compressed) * ps
      avail = (free + inactive + speculative) * ps
      swapcmd = "sysctl vm.swapusage"
      swapcmd | getline swap
      close(swapcmd)
      printf "              total        used       avail\n"
      printf "Mem:  %10.1fG %10.1fG %10.1fG\n", total/2^30, used/2^30, avail/2^30
      print swap
    }'
}

# Paste without trailing newlines
paste-strip-newlines() {
  local paste
  if command -v pbpaste &>/dev/null; then
    paste=$(pbpaste | perl -pe 'chomp if eof')
  elif command -v xclip &>/dev/null; then
    paste=$(xclip -selection clipboard -o | perl -pe 'chomp if eof')
  fi
  LBUFFER+=$paste
}
zle -N paste-strip-newlines
bindkey '^V' paste-strip-newlines

# SOPS
export SOPS_AGE_KEY_FILE="$HOME/.age/keys.txt"

# Java
export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which java))))" 2>/dev/null

# Platform-specific
if [[ "$(uname -s)" == "Darwin" ]]; then
  # Homebrew (for cask apps Nix can't handle)
  eval "$(/opt/homebrew/bin/brew shellenv zsh)" 2>/dev/null
fi
