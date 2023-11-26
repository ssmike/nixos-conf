{
  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs";
    yandex-workstation = {
      url = "github:ssmike/yandex-workstation-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dotfiles.url = "github:ssmike/dotfiles/carbon";
  };

  outputs = {
    nixpkgs,
    yandex-workstation,
    dotfiles,
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
        dnsutils
        htop
        git
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
          virtualenv
        ]))
      ] ++ dev_common;
      golang = with pkgs; [
        go
        gopls
      ] ++ dev_common;
      hs = with pkgs; [
        (haskellPackages.ghcWithPackages (pkgs: [ pkgs.random pkgs.randomgen pkgs.parallel ]))
        haskell-language-server
      ];
      clj = with pkgs; [
        clojure
        clojure-lsp
        leiningen
      ];
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
          modules = [
            yandex-workstation.nixosModules.default

            ./configuration.nix

            ({...}:{
              users.users.michael.packages = 
              with dotfiles.packages.${system}; [
                dotfiles-scripts
              ];
            })

            ({...}:{
              # services.osquery-custom.enable = pkgs.lib.mkForce false;
              systemd.services.osqueryd.serviceConfig = {
                ReadOnlyPaths=["/"];
                InaccessiblePaths = [
                  "/home/michael/.gnupg"
                  "/home/michael/.password-store"
                  "/home/michael/.ssh/id_rsa"
                  "/home/michael/.ssh/id_rsa.pub"
                ];
                ReadWritePaths=["/var/lib/osquery" "/run"];
              };
            })
          ];
       };
    };
    packages.${system} = pkgs // {
      qtwebengine = pkgs.libsForQt5.qtwebengine;
    };
    devShells.${system} = {
      cpp = devShell envs.cpp;
      arcadia = devShell envs.arcadia;
      python = devShell envs.py;
      haskell = devShell envs.hs;
      golang = devShell envs.golang;
      clojure = devShell envs.clj;
    };
  };
}
