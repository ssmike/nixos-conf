{
  inputs = {
    nixpkgs.url = github:NixOs/nixpkgs;
  };

  outputs = {
    nixpkgs,
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
  };
}
