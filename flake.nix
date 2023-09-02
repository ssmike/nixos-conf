{
  inputs = {
    home-manager.url = github:nix-community/home-manager;
    nixpkgs.url = github:NixOs/nixpkgs;
    yandex-workstation.url = github:ssmike/yandex-workstation-utils;
  };

  outputs = {
    nixpkgs,
    yandex-workstation,
    home-manager,
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
      go = with pkgs; [
        go
        gopls
      ] ++ dev_common;
      hs = with pkgs; [
        (haskellPackages.ghcWithPackages (pkgs: [ pkgs.random pkgs.randomgen pkgs.parallel ]))
        haskell-language-server
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
              # services.osquery-custom.enable = pkgs.lib.mkForce false;
              systemd.services.osqueryd.serviceConfig = {
                ReadOnlyPaths=["/"];
                InaccessiblePaths = [
                  "/home/michael/.gnupg"
                  "/home/michael/.password-store"
                  "/home/michael/.ssh/id_rsa"
                  "/home/michael/.ssh/id_rsa.pub"
                  "/home/michael/dotfiles/.ssh/id_rsa"
                  "/home/michael/dotfiles/.ssh/id_rsa.pub"
                ];
                ReadWritePaths=["/var/lib/osquery" "/run"];
              };
            })

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.michael = import ./michael.nix;
            }
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
    };
  };
}
