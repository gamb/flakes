{
  description = "NixOS and Home Manager configurations of adamgamble";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    llm-agents.url = "github:numtide/llm-agents.nix";
    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, home-manager, emacs-overlay, llm-agents, mattpocock-skills, ... }:
    let
      overlays = [
        emacs-overlay.overlays.default
        # Use upstream packages to preserve Numtide binary-cache compatibility.
        (final: _prev: {
          llm-agents = llm-agents.packages.${final.stdenv.hostPlatform.system};
        })
      ];
    in
    {
      nixosConfigurations = {
        seria = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./machines/seria/configuration.nix
            home-manager.nixosModules.home-manager
            {
              nixpkgs.overlays = overlays;
            }
          ];
        };
      };

      devShells = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (
        shellSystem:
        let
          shellPkgs = nixpkgs.legacyPackages.${shellSystem};
        in
        {
          default = shellPkgs.mkShell {
            packages = [
              shellPkgs.just
              home-manager.packages.${shellSystem}.home-manager
            ];
          };
        }
      );

      homeConfigurations = {
        macbook = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            inherit overlays;
          };

          modules = [ ./home-manager/macbook.nix ];

          extraSpecialArgs = { inherit mattpocock-skills; };
        };
      };
    };
}
