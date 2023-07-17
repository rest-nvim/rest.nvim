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
            luaEnv = pkgs."lua${luaVersion}".withPackages (lp: with lp; [
              busted
              luacheck
              luarocks
            ]);
          in
          pkgs.mkShell {
            name = "rest-nvim";
            buildInputs = [
              pkgs.sumneko-lua-language-server
              luaEnv
              pkgs.stylua
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
                };
              packDirArgs.myNeovimPackages = myVimPackage;
            in 
              ''
              export DEBUG_PLENARY="debug"
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
          ci = let 
            neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
              plugins = with pkgs.vimPlugins; [
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
              (mkDevShell "jit").overrideAttrs(oa: {
                buildInputs = oa.buildInputs ++ [ myNeovim ];
              });

          luajit = mkDevShell "jit";
          lua-51 = mkDevShell "5_1";
          lua-52 = mkDevShell "5_2";
        };
      });
}

