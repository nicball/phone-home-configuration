{
  description = "Home Manager configuration of Nicball";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nicpkgs.url = "github:nicball/nicpkgs";
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
    factorio-bot = {
      url = "github:nicball/midymidy-factorio-webservice";
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
        modules = [
          ./home.nix
          inputs.nix-index-database.hmModules.nix-index
          nicpkgs.homeModules.${system}.instaepub
          nicpkgs.homeModules.${system}.cloudflare-ddns
        ];
        extraSpecialArgs = {
          inherit (inputs) fvckbot transfersh factorio-bot;
          inherit system;
          nicpkgs = nicpkgs.packages.${system};
          niclib = nicpkgs.niclib.${system};
        };
      };
    };
}
