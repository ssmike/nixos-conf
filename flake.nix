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
    envs = {
      cpp = let
              llvm = pkgs.llvmPackages_14;
            in
            with pkgs; [
              clang-tools
              llvm.clang
              llvm.libcxxabi
              cmake
              gnumake
              protobuf
            ];
    };
    devShell = deps: with pkgs; stdenv.mkDerivation
          {
           name = "cpp env";
           phases = [ "installPhase" ];
           installPhase = ''
              mkdir -p $out
             '';
           propagatedBuildInputs = deps;
          };
  in
  { # Removes all phases except installPhase
    nixosConfigurations = {
       inherit system;
       ssmike-thinkpad = lib.nixosSystem {
          specialArgs = {
            inherit envs;
          };
          modules = [ ./configuration.nix  ];
       };
    };
    devShells.cpp = devShell envs.cpp;
  };
}
