{
  config,
  lib,
  pkgs,
  ...
}:

let
  noShortcuts = lib.hm.gvariant.mkEmptyArray lib.hm.gvariant.type.string;
in
{
  imports = [
    ../../home-manager/emacs.nix
    ../../home-manager/fonts.nix
    ../../home-manager/git.nix
  ];

  home.username = "gamble";
  home.homeDirectory = "/home/gamble";
  home.stateVersion = "26.05";

  home.packages = [
    (pkgs.aspellWithDicts (dicts: with dicts; [ en ]))
    pkgs.fzf
    pkgs.jq
    pkgs.llm-agents.codex
    pkgs.llm-agents.codex-acp
    pkgs.ripgrep
    pkgs.tree
    pkgs.sqlite
  ];

  programs.vicinae = {
    enable = true;
    systemd.enable = true;
  };

  programs.gnome-shell = {
    enable = true;
    extensions = [ { package = pkgs.gnomeExtensions.vicinae; } ];
  };

  # Release Super shortcuts used as Meta in Emacs, except the launcher binding.
  dconf.settings = {
    "org/gnome/mutter".overlay-key = "";
    "org/gnome/mutter/keybindings".switch-monitor = [ "XF86Display" ];
    "org/gnome/shell/keybindings" = {
      toggle-application-view = [ "F8" ];
      toggle-message-tray = noShortcuts;
      toggle-quick-settings = noShortcuts;
      focus-active-notification = noShortcuts;
    };
    "desktop/ibus/panel/emoji".hotkey = noShortcuts;
    "org/gnome/settings-daemon/plugins/media-keys" = {
      rotate-video-lock-static = [ "XF86RotationLockToggle" ];
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae" = {
      name = "Toggle Vicinae";
      command = "${lib.getExe config.programs.vicinae.package} toggle";
      # GNOME sees this modifier after keyd's left Ctrl/Super swap.
      binding = "<Super>space";
    };
    "org/gnome/desktop/wm/keybindings" = {
      switch-group = [ "<Alt>Above_Tab" ];
      switch-group-backward = [ "<Shift><Alt>Above_Tab" ];
      switch-input-source = noShortcuts;
      switch-input-source-backward = noShortcuts;
    };
  };

  programs.fish.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
