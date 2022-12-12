{
  description = "rest.nvim: A fast Neovim http client written in Lua";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        mkPackage = luaVersion:
          pkgs."lua${luaVersion}Packages".luarocks;

        mkDevShell = luaVersion:
          let
            luaPkgs = pkgs."lua${luaVersion}".pkgs;
            luaEnv = pkgs."lua${luaVersion}".withPackages (lp: with lp; [
              luacheck
              luarocks
              (pkgs.lib.hiPrio plenary-nvim)
            ]);
          in
          luaPkgs.luarocks.overrideAttrs (oa: {
            name = "luarocks-dev";
            buildInputs = oa.buildInputs ++ [
              pkgs.sumneko-lua-language-server
              luaEnv
              pkgs.stylua
              # pkgs.neovim  # assume user has one already installed
            ];
          });

      in
      {

        packages = {
          default = self.packages.${system}.luarocks-51;
          luarocks-51 = mkPackage "5_1";
          luarocks-52 = mkPackage "52";
        };

        devShells = {
          default = self.devShells.${system}.luajit;
          luajit = mkDevShell "jit";
          lua-51 = mkDevShell "5_1";
          lua-52 = mkDevShell "5_2";
        };
      });
}

