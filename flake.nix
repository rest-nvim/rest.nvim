# I have no idea what I'm writing.
{
  description = "rest.nvim: A fast Neovim http client written in Lua";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    neorocks.url = "github:nvim-neorocks/neorocks";
    flake-utils.url = "github:numtide/flake-utils";
    cats-doc.url = "github:boltlessengineer/vimcats?ref=feat/aarch64-linux";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    neorocks,
    flake-utils,
    ...
  }: let
    test-overlay = import ./nix/test-overlay.nix {
      inherit self inputs;
    };
  in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            neorocks.overlays.default
            test-overlay
          ];
        };

        devShell = pkgs.mkShell {
          name = "rest.nvim devShell";
          shellHook = ''
          '';
          buildInputs = [
            pkgs.sumneko-lua-language-server
            pkgs.stylua
            pkgs.docgen
            (pkgs.lua5_1.withPackages (ps: with ps; [luarocks luacheck]))
          ];
        };
      in
      {
        packages = {
          default = self.packages.${system}.luarocks-51;
          luarocks-51 = pkgs.lua51Packages.luarocks;
          inherit
            (pkgs)
            docgen
            ;
        };

        devShells = {
          default = devShell;
          inherit devShell;
        };

        checks = {
          neorocks-test = pkgs.neorocksTest {
            src = self;
            name = "rest.nvim";
          };
        };
      });
}
