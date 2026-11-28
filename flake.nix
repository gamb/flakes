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
    cursor-plugins = {
      url = "github:cursor/plugins";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      emacs-overlay,
      llm-agents,
      cursor-plugins,
      ...
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      overlays = [
        emacs-overlay.overlays.default
        # Use upstream packages to preserve Numtide binary-cache compatibility.
        (final: _prev: {
          llm-agents = llm-agents.packages.${final.stdenv.hostPlatform.system};
        })
      ];
    in
    {
      devShells = forAllSystems (
        shellSystem:
        let
          shellPkgs = nixpkgs.legacyPackages.${shellSystem};
        in
        {
          default = shellPkgs.mkShell {
            packages = with shellPkgs; [
              just
              nixfmt
              home-manager.packages.${shellSystem}.home-manager
            ];
          };
        }
      );

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

      homeConfigurations = {
        macbook = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            inherit overlays;
          };

          modules = [ ./home-manager/macbook.nix ];

          extraSpecialArgs = { inherit cursor-plugins; };
        };
      };
    };
}
