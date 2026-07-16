{
  description = "Ryan's portable dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
      forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f rec {
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        isDarwin = pkgs.stdenv.isDarwin;
        isLinux = pkgs.stdenv.isLinux;
      });
    in {
      packages = forEachSystem ({ pkgs, isDarwin, isLinux, ... }: {
        default = pkgs.buildEnv {
          name = "ryan-env";
          paths = with pkgs; [
            # Shell
            zsh
            oh-my-zsh
            direnv

            # Editor
            neovim

            # Terminal
            ] ++ (if isLinux then [ pkgs.ghostty ] else []) ++ [

            # Languages (latest stable)
            nodejs_22
            yarn
            deno
            dotnet-sdk_10
            rustup
            python314
            jdk
            lua5_4
            beamPackages.elixir
            beamPackages.erlang

            # Cloud / Infra
            azure-cli
            podman

            # CLI tools
            ripgrep
            fd
            fzf
            jq
            yq-go
            bat
            delta
            cloc
            pandoc
            stow
            age
            sops
            curl
            wget
            htop
            tree

            # Dev tools
            lazygit
            watchman
          ];
        };
      });

      devShells = forEachSystem ({ pkgs, ... }: {
        default = pkgs.mkShell {
          packages = [ self.packages.${pkgs.system}.default ];
        };
      });
    };
}
