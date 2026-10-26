{ pkgs, ... }:

let
  # eMudhra compromise: bundle-based clients do not inherit Apple's trustd
  # revocations. Use the same root blacklist as seria for CLI tools.
  # Revisit once the pinned CA bundle includes the upstream remediation.
  # https://github.com/NixOS/nixpkgs/issues/576485
  cacertWithBlacklist = pkgs.cacert.override {
    blacklist = [
      "Comodo AAA Services root"
      "emSign ECC Root CA - G3"
      "emSign Root CA - C1"
      "emSign ECC Root CA - C3"
    ];
  };
  # Preserve OpenSSL's explicit distrust flags.
  caBundle = "${cacertWithBlacklist}/etc/ssl/certs/ca-bundle.crt";
in
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
    SSL_CERT_FILE = caBundle;
    NIX_SSL_CERT_FILE = caBundle;
    CURL_CA_BUNDLE = caBundle;
    GIT_SSL_CAINFO = caBundle;
    REQUESTS_CA_BUNDLE = caBundle;
  };
}
