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

        packages =
          let
            buildCBinary = name: epiflake.lib.BuildEpitechCBinary
              pkgs
              {
                inherit name;
                src = ./.;

                enableParallelBuilding = true;
                V = 1;
              };
          in
          rec {
            default = foray;
            foray = (buildCBinary "foray");
          };
      });
}
