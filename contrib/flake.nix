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

        mkDevShell = luaVersion:
          let
            # luaPkgs = pkgs."lua${luaVersion}".pkgs;
            luaEnv = pkgs."lua${luaVersion}".withPackages (lp: with lp; [
              luacheck
              luarocks
            ]);
            neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
              plugins = with pkgs.vimPlugins; [
                { 
                  plugin = packer-nvim;
                  type = "lua";
                  config = ''
                    require('packer').init({
                      luarocks = {
                        python_cmd = 'python' -- Set the python command to use for running hererocks
                      },
                    })
                    -- require my own manual config
                    require('init-manual')
                  '';
                }
                { plugin = (nvim-treesitter.withPlugins (
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
          pkgs.mkShell {
            name = "rest-nvim";
            buildInputs = [
              pkgs.sumneko-lua-language-server
              luaEnv
              pkgs.stylua
              myNeovim
              # pkgs.neovim  # assume user has one already installed
            ];

            shellHook = let 
              myVimPackage = with pkgs.vimPlugins; {
                      start = [ plenary-nvim (nvim-treesitter.withPlugins (
                      plugins: with plugins; [
                        tree-sitter-lua
                        tree-sitter-http
                        tree-sitter-json
                      ]
                    ))];
                      # opt = map (x: x.plugin) pluginsPartitioned.right;
                };
              # };
              packDirArgs.myNeovimPackages = myVimPackage;
            in 
              ''
                cat <<-EOF > minimal.vim
                  set rtp+=.
                  set packpath^=${pkgs.vimUtils.packDir packDirArgs}
                EOF
              '';
          };

      in
      {

        # packages = {
        #   default = self.packages.${system}.luarocks-51;
        #   luarocks-51 = mkPackage "5_1";
        #   luarocks-52 = mkPackage "5_2";
        # };

        devShells = {
          default = self.devShells.${system}.luajit;
          luajit = mkDevShell "jit";
          lua-51 = mkDevShell "5_1";
          lua-52 = mkDevShell "5_2";
        };
      });
}

