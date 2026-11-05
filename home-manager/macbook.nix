{ pkgs, ... }:

{
  imports = [
    ./claude.nix
    ./emacs.nix
    ./fonts.nix
    ./git.nix
  ];

  home.username = "adamgamble";
  home.homeDirectory = "/Users/adamgamble";

  home.stateVersion = "25.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion

  home.packages = [
    (pkgs.aspellWithDicts (dicts: with dicts; [ en ]))
    pkgs.llm-agents.claude-agent-acp
    pkgs.llm-agents.codex-acp
    pkgs.coreutils-prefixed
    pkgs.entr
    pkgs.fd
    pkgs.fish
    pkgs.gh
    pkgs.git-absorb
    pkgs.jq
    pkgs.just
    pkgs.ledger
    pkgs.nixfmt
    pkgs.prettier
    pkgs.ripgrep
    pkgs.sqlite
    pkgs.texlive.combined.scheme-basic
    pkgs.tree
    pkgs.uiua
    pkgs.unzip
  ];

  programs.fish = {
    enable = true;
    # The nix installer writes /etc/fish/conf.d/nix.fish only when fish already
    # exists. Fish arrived via home-manager after nix, so put nix on PATH here.
    shellInit = ''
      if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
          source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      end
    '';
    functions.fish_prompt = ''
      echo -n "% "
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "emacsclient";
  };
}
