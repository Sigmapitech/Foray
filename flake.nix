{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    epiflake = {
      url = "github:Sigmapitech/EpiFlake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, epiflake, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        formatter = pkgs.nixpkgs-fmt;

        devShells.default = pkgs.mkShell {
          hardeningDisable = [ "all" ];
          inputsFrom = pkgs.lib.attrsets.attrValues packages;
          packages = with (epiflake.lib.ShellPkgs pkgs);
            base ++ debug ++ testing;
        };

        packages = rec {
            default = foray;
            foray = pkgs.stdenv.mkDerivation {
                name = "foray";
                src = ./.;
                V = 1;

                enableParallelBuilding = true;
                nativeBuildInputs = [ pkgs.makeWrapper ];

                buildPhase = ''
                  runHook preBuild

                  ${pkgs.gnumake}/bin/make

                  runHook postBuild
                '';

                installPhase = ''
                  runHook preBuild

                  mkdir -p $out/bin
                  cp foray $out/bin/foray

                  mkdir -p $out/lib
                  cp libforay.so $out/lib/libforay.so

                  runHook postBuild
                '';

                postFixup = ''
                  wrapProgram $out/bin/foray \
                    --set LD_LIBRARY_PATH "LD_LIBRARY_PATH:$out/lib"
                '';
            };
          };
      });
}
