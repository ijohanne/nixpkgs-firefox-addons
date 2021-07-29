let

  # Pinned Nixpkgs to known working commit. Pinned 2020-09-11.
  nixpkgs = builtins.fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs/archive/d0044b0e7d531a7a28d4552582b98e8b3953c6cb.tar.gz";
    sha256 = "01vg18lj4hv2q5vw5in5vv65m88xyikw53614rgrjnga6jbypnb6";
  };

in { pkgs ? import nixpkgs { } }:

let

  haskellPackages = pkgs.haskellPackages;

in haskellPackages.developPackage {
  root = ./.;
  modifier = drv:
    pkgs.haskell.lib.overrideCabal drv (attrs: {
      buildTools = (attrs.buildTools or [ ]) ++ [
        haskellPackages.cabal-install
        haskellPackages.haskell-language-server
        pkgs.nixfmt
      ];
    });
}
