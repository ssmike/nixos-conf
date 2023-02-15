{
  inputs = {
    nixpkgs.url = github:NixOs/nixpkgs;
    home-manager = {
       url = github:nix-community/home-manager;
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  }:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    nixosConfigurations = {
       inherit system;
       ssmike-thinkpad = lib.nixosSystem {
          modules = [ ./configuration.nix  ];
       };
    };
    homeConfigurations.michael = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./michael.nix
      ];
    };
  };
}
