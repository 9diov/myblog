{
  description = "A basic Nix flake for a Hugo blog";

  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";         ## Most stable, less downloads
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        hugo = pkgs.hugo;
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          name = "my-blog";
          src = ./.;

          buildInputs = [ hugo ];

          buildPhase = ''
            hugo --minify
          '';

          installPhase = ''
            mkdir -p $out
            cp -r public/* $out/
          '';
        };

        devShells.default = pkgs.mkShell {
          packages = [ hugo ];
          shellHook = ''
            echo "📝 Welcome to your Hugo dev shell"
            echo "👉 Run \`hugo server\` to start developing"
          '';
        };
      });
}
