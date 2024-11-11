{
  self,
  inputs,
}: final: prev: let
  mkNeorocksTest = name: nvim:
    with final;
      neorocksTest {
        inherit name;
        pname = "rest.nvim";
        src = self;
        neovim = nvim;
        luaPackages = ps:
          with ps; [
            nvim-nio
            mimetypes
            xml2lua
            fidget-nvim
            # FIXME: this doesn't work
            # tree-sitter-http
          ];
        extraPackages = [
        ];

        preCheck = ''
          # Neovim expects to be able to create log files, etc.
          export HOME=$(realpath .)
          export LUA_PATH="$(luarocks path --lr-path --lua-version 5.1 --local)"
          export LUA_CPATH="$(luarocks path --lr-cpath --lua-version 5.1 --local)"
          # luarocks install --local --lua-version 5.1 --dev tree-sitter-http
        '';
      };
  docgen = final.writeShellApplication {
    name = "docgen";
    runtimeInputs = [
      inputs.cats-doc.packages.${final.system}.default
    ];
    text = /*bash*/ ''
      mkdir -p doc
      lemmy-help lua/rest-nvim/{init,commands,autocmds,config/init}.lua > doc/rest-nvim.txt
      lemmy-help lua/rest-nvim/{api,client/init,parser/init,script/init,cookie_jar,utils,logger}.lua > doc/rest-nvim-api.txt
      lemmy-help lua/rest-nvim/client/curl/{cli,utils}.lua > doc/rest-nvim-client-curl.txt
    '';
  };
in {
  integration-stable = mkNeorocksTest "integration-stable" final.neovim;
  integration-nightly = mkNeorocksTest "integration-nightly" final.neovim-nightly;
  inherit docgen;
}
