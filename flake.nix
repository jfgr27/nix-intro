{
  inputs = {
    cargo2nix.url = "github:cargo2nix/cargo2nix/c6f33051f412352f293e738cc8da6fd4c457080f";
    flake-utils.url = "github:numtide/flake-utils/4022d587cbbfd70fe950c1e2083a02621806a725";
    nixpkgs.url = "github:NixOS/nixpkgs/6ca3894050d1b7fd32719a2eb2591f7826a45ac7";
  };

  outputs = inputs: with inputs;
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = { allowBroken = true; };
          crossSystem = {config = "x86_64-unknown-linux-gnu"; };
          overlays = [cargo2nix.overlays.default];
        };

        rustPkgs = pkgs.rustBuilder.makePackageSet {
          rustVersion = "2023-10-15";
          rustChannel = "nightly";
          packageFun = import ./Cargo.nix;
          extraRustComponents = ["clippy" "miri"];
        };

        ubuntuBase =   pkgs.dockerTools.pullImage {
          imageName = "ubuntu";
          imageDigest  = "sha256:6042500cf4b44023ea1894effe7890666b0c5c7871ed83a97c36c76ae560bb9b";
          sha256 = "sha256-thTJ60Hf0IB5wC93ujIEuVChlAXQIuO9/lDFENAhwWs=";
          finalImageTag = "latest";
          finalImageName = "ubuntu";
        };

      in rec {
        packages = {
          nix-gql-rs = (rustPkgs.workspace.nix-gql-rs {});
          default = pkgs.dockerTools.buildImage {
            name = "demo";
            tag = "latest";
            fromImage = ubuntuBase;
            copyToRoot = rustPkgs.workspace.nix-gql-rs {};
            config = {
              Cmd = [ "/bin/nix-gql-rs" ];
            };
          };
        };
        devShells = rec {
          default = (rustPkgs.workspaceShell {
            packages = [
              nixpkgs.legacyPackages.${system}.rust-analyzer
              nixpkgs.legacyPackages.${system}.just
            ];
          });
        };
      }
    );
}
