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
    transfersh = {
      url = "github:dutchcoders/transfer.sh/v1.4.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
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
        modules = [ ./home.nix inputs.nix-index-database.hmModules.nix-index ];
        extraSpecialArgs = {
          inherit (inputs) fvckbot transfersh;
          inherit system;
          npkgs = nicpkgs.packages.${system};
          nlib = nicpkgs.lib.${system};
        };
      };
    };
}
