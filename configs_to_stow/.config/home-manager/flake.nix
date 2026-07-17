{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      homeConfigurations.sadiq = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = { gitUserName = "sadiq_from_thinkpad"; };

        modules = [
          ./home.nix
        ];
      };
    };
}
