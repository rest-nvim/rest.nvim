# I have no idea what I'm writing.
{
  description = "rest.nvim: A fast Neovim http client written in Lua";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    neorocks.url = "github:nvim-neorocks/neorocks";
    flake-parts.url = "github:hercules-ci/flake-parts";
    cats-doc.url = "github:mrcjkb/vimcats";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    neorocks,
    flake-parts,
    ...
  }: let
    test-overlay = import ./nix/test-overlay.nix {
      inherit self inputs;
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem = {
        config,
        self',
        inputs',
        system,
        ...
      }: let
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
            export LUA_PATH="$(luarocks path --lr-path --lua-version 5.1 --local)"
            export LUA_CPATH="$(luarocks path --lr-cpath --lua-version 5.1 --local)"
            # HACK: install tree-sitter-http manually
            # TODO: add it as a test dependency using nix
            luarocks install --local --lua-version 5.1 --dev tree-sitter-http
          '';
          buildInputs = [
            pkgs.sumneko-lua-language-server
            pkgs.stylua
            pkgs.docgen
            pkgs.neovim
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
          inherit
            (pkgs)
            # integration-stable
            integration-nightly
            ;
        };
      };
    };
}
