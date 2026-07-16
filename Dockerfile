FROM nixos/nix

RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

RUN nix profile install nixpkgs#stow nixpkgs#git

WORKDIR /root/.dotfiles
COPY . .

RUN git init -q && git add -A && git config user.email "test@test" && git config user.name "test" && git commit -qm init

RUN nix profile install .
RUN cd stow && stow -t /root zsh ghostty nvim herdr pi markdownlint

CMD ["zsh"]
