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
    envs = rec {
      dev_common = with pkgs; [
        ripgrep
        jq
        nmap
        lsof
        netcat
        gdb
        ctags
        mosh
      ];
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
            ]
            ++ dev_common;
      py = with pkgs; [
        (python3.withPackages (ps: with ps; [
          python-lsp-server
        ]))
      ] ++ dev_common;
      arcadia = (with pkgs; [glibc python3]) ++ envs.cpp;
    };
    devShell = deps: pkgs.mkShell {packages = deps;};
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
    devShells.${system} = {
      cpp = devShell envs.cpp;
      arcadia = devShell envs.arcadia;
      python = devShell envs.py;
    };
  };
}
