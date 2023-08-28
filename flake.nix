{
  description = "rest.nvim: A fast Neovim http client written in Lua";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    neorocks.url = "github:nvim-neorocks/neorocks";
  };

  outputs = { self, nixpkgs, flake-utils, neorocks, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        mkDevShell = luaVersion:
          let
            luaEnv = pkgs."lua${luaVersion}".buildEnv.override {
              extraLibs = with pkgs."lua${luaVersion}".pkgs; [
              busted
              luacheck
              luarocks
              plenary-nvim

            ];
            # plenary vendors luassert
            ignoreCollisions = true;
          };
          in
          pkgs.mkShell {
            name = "rest-nvim";
            buildInputs = [
              pkgs.sumneko-lua-language-server
              luaEnv
              neorocks.packages.${system}.neorocks
              pkgs.stylua
            ];

            shellHook =
              let
                myVimPackage = with pkgs.vimPlugins; {
                  start = [
                    plenary-nvim
                    (nvim-treesitter.withPlugins (
                      plugins: with plugins; [
                        tree-sitter-lua
                        tree-sitter-http
                        tree-sitter-json
                      ]
                    ))
                  ];
                };
                packDirArgs.myNeovimPackages = myVimPackage;
              in
              ''
                export DEBUG_PLENARY="debug"
                luarocks config --scope project lua_interpreter neolua

                cat <<-EOF > minimal.vim
                  set rtp+=.
                  set packpath^=${pkgs.vimUtils.packDir packDirArgs}
                EOF
              '';
          };

      in
      {

        devShells = {
          default = self.devShells.${system}.luajit;
          ci =
            let
              neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
                plugins = with pkgs.vimPlugins; [
                  {
                    plugin = (nvim-treesitter.withPlugins (
                      plugins: with plugins; [
                        tree-sitter-lua
                        tree-sitter-http
                        tree-sitter-json
                      ]
                    ));
                  }
                  { plugin = plenary-nvim; }
                ];
                customRC = "";
                wrapRc = false;
              };
              myNeovim = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped neovimConfig;
            in
            (mkDevShell "jit").overrideAttrs (oa: {
              buildInputs = oa.buildInputs ++ [ myNeovim ];
            });

          luajit = mkDevShell "jit";
          lua-51 = mkDevShell "5_1";
          lua-52 = mkDevShell "5_2";
        };
      });
}
