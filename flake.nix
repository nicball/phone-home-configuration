{
  description = "Home Manager configuration of Nicball";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nicpkgs = {
      url = "github:nicball/nicpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fvckbot = {
      url = "github:nicball/fvckbot";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nicpkgs, ... }@inputs:
    let
      system = "aarch64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations.phablet = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
        extraSpecialArgs = {
          inherit (inputs) fvckbot;
          inherit system;
          npkgs = nicpkgs.packages.${system};
          nlib = nicpkgs.lib.${system};
        };
      };
    };
}
