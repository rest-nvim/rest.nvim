# I have no idea what I'm writing.
{
  description = "rest.nvim: A fast Neovim http client written in Lua";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    neorocks.url = "github:nvim-neorocks/neorocks";
    flake-parts.url = "github:hercules-ci/flake-parts";
    vimcats.url = "github:mrcjkb/vimcats";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    neorocks,
    flake-parts,
    ...
  }: let
    name = "rest.nvim";
    plugin-overlay = import ./nix/plugin-overlay.nix {
      inherit self;
    };
    test-overlay = import ./nix/test-overlay.nix {
      inherit self inputs;
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = builtins.attrNames nixpkgs.legacyPackages;
      perSystem = attrs @ {
        system,
        ...
      }: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            neorocks.overlays.default
            test-overlay
            plugin-overlay
          ];
        };
      in {
        packages = {
          default = self.packages.${system}.luarocks-51;
          luarocks-51 = pkgs.lua51Packages.luarocks;
          inherit
            (pkgs)
            docgen
            sync-readme
            ;
        };
        devShells.default = pkgs.mkShell {
          name = "rest.nvim devShell";
          shellHook = ''
            export LUA_PATH="$(luarocks path --lr-path --lua-version 5.1 --local)"
            export LUA_CPATH="$(luarocks path --lr-cpath --lua-version 5.1 --local)"
            export TREE_SITTER_HTTP_PLUGIN_DIR=${pkgs.tree-sitter-http-plugin}
            export REST_NVIM_PLUGIN_DIR=${pkgs.rest-nvim-dev}
          '';
          buildInputs = [
            pkgs.sumneko-lua-language-server
            pkgs.stylua
            pkgs.docgen
            pkgs.sync-readme
            (pkgs.lua5_1.withPackages (ps: with ps; [luarocks luacheck]))
          ];
        };

        checks = {
          inherit
            (pkgs)
            integration-stable
            integration-nightly
            ;
        };
      };
    };
}
