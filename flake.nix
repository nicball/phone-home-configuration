{
  description = "Home Manager configuration of Nicball";

  inputs = {
    home-manager = {
      url = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nicpkgs.url = "github:nicball/nicpkgs";
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
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
          ({ ... }: { home.sessionVariables.NIX_PATH = "nixpkgs=${nixpkgs}:home-manager=${home-manager}:nicpkgs=${nicpkgs}"; })
        ];
      };
    };
}
