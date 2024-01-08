{
  description = "Home Manager configuration of Nicball";

  inputs = {
    home-manager = {
      url = "home-manager";
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

  outputs = { nixpkgs, home-manager, nicpkgs, nix-index-database, ... }@inputs:
    let
      system = "aarch64-linux";
      pkgs = import nixpkgs { inherit system; overlays = [ nicpkgs.overlays.default ]; };
    in {
      homeConfigurations.phablet = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = with nicpkgs.homeModules; [
          ./home.nix
          nix-index-database.hmModules.nix-index
          instaepub
          cloudflare-ddns
          # ({ ... }: { nixpkgs.overlays = [ nicpkgs.overlays.default ]; })
        ];
        extraSpecialArgs = {
          inherit (inputs) fvckbot transfersh factorio-bot;
        };
      };
    };
}
