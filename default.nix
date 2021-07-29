{ pkgs ? import <nixpkgs> { } }:
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
