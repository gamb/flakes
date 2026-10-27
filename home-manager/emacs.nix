{
  config,
  lib,
  pkgs,
  ...
}:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  emacsBase = if isDarwin then pkgs.emacs-unstable else pkgs.emacs-unstable-pgtk;
  emacsPkg = config.programs.emacs.finalPackage;
  emacsclient-app = pkgs.callPackage ../packages/emacsclient-app.nix {
    emacs = emacsPkg;
    # icon = ../assets/emacsclient.icns; # uncomment to use a custom icon
  };
in
{
  home.file."Applications/Emacs Client.app" = lib.mkIf isDarwin {
    source = emacsclient-app;
  };

  # Launch the daemon from inside Emacs.app rather than bin/emacs, so its
  # NSBundle resolves to the app and GUI frames get the real Emacs icon
  # instead of the generic one. Home Manager wraps these args in a
  # wait4path guard itself, so pass them plain like the upstream module.
  launchd.agents.emacs = lib.mkIf isDarwin {
    config.ProgramArguments = lib.mkForce [
      "${config.home.homeDirectory}/.nix-profile/Applications/Emacs.app/Contents/MacOS/Emacs"
      "--fg-daemon"
    ];
  };

  programs.emacs = {
    enable = true;
    package = (pkgs.emacsPackagesFor emacsBase).emacsWithPackages (
      epkgs:
      with epkgs;
      [
        (epkgs.trivialBuild {
          pname = "eglot-hierarchy";
          version = "unstable";
          src = pkgs.fetchFromGitHub {
            owner = "dolmens";
            repo = "eglot-hierarchy";
            rev = "main";
            sha256 = "sha256-Eh+gglFAv7WPVTi5UP6otlulxxkRWzEPkbPw7EJZ7l4=";
          };
          packageRequires = with epkgs; [ eglot ];
        })
        agent-shell
        browse-kill-ring
        cape
        cider
        clojure-mode
        consult
        corfu
        ef-themes
        eat
        embark-consult
        envrc
        exec-path-from-shell
        flymake
        focus
        # nixpkgs 26.05 ships ghostel 0-unstable-2026-05-06, whose zig module
        # build fails on Darwin with DarwinSdkNotFound: ghostty's build.zig
        # runs `xcrun --show-sdk-path`, which does not exist in the sandbox.
        # nixpkgs fixed this in 5370753 (June 2026) by adding xcbuild, which
        # provides an xcrun shim. Backport that until the package catches up.
        (
          let
            module = ghostel.passthru.module.overrideAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ lib.optionals isDarwin [ pkgs.xcbuild ];
            });
            libExt = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;
          in
          ghostel.overrideAttrs (old: {
            preBuild = ''
              install ${module}/lib/libghostel-module${libExt} ghostel-module${libExt}
            '';
            passthru = old.passthru // {
              inherit module;
            };
          })
        )
        gptel
        hide-mode-line
        highlight-symbol
        ibuffer-project
        j-mode
        jarchive
        jtsx
        justl
        ledger-mode
        magit
        marginalia
        markdown-mode
        minions
        modus-themes
        move-dup
        nim-mode
        nix-ts-mode
        ocaml-ts-mode
        orderless
        org-roam
        paredit
        reformatter
        rg
        slime
        symbol-overlay
        tempel
        tuareg
        uiua-mode
        use-package
        vertico
        vterm
        which-key
        whole-line-or-region
        xref
        (treesit-grammars.with-grammars (
          treesit-pkgs: with treesit-pkgs; [
            tree-sitter-typescript
            tree-sitter-ocaml
            tree-sitter-ruby
            tree-sitter-nix
            tree-sitter-tsx
            tree-sitter-json
            tree-sitter-javascript
          ]
        ))
      ]
      ++ lib.optionals isDarwin [ epkgs.ns-auto-titlebar ]
    );
    extraConfig = builtins.readFile ../config.el;
  };

  services.emacs = {
    enable = true;
    startWithUserSession = true;

    client = {
      enable = true;
    };
  };

}
