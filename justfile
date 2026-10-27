init:
  nix run home-manager/release-25.05 -- init --switch

build:
  home-manager build --flake .#macbook

switch:
  home-manager switch --flake .#macbook -b backup

update-lock:
  nix flake update
  git add flake.lock
  git commit -m "Update flake.lock" -- flake.lock

expire:
  home-manager expire-generations "-30 days"

garbage:
  nix-collect-garbage --delete-older-than 14d

seria-rebuild:
  sudo nixos-rebuild switch --flake path:.#seria

fmt:
  nix fmt
