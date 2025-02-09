{
  self,
  inputs,
}: final: prev: {
  docgen = final.writeShellApplication {
    name = "docgen";
    runtimeInputs = [
      inputs.vimcats.packages.${final.system}.default
    ];
    text = /* bash */ ''
      mkdir -p doc
      vimcats lua/rest-nvim/{init,commands,autocmds,config/init}.lua > doc/rest-nvim.txt
      vimcats lua/rest-nvim/{api,client/init,parser/init,script/init,cookie_jar,utils,logger}.lua > doc/rest-nvim-api.txt
      vimcats lua/rest-nvim/client/curl/{cli,utils}.lua > doc/rest-nvim-client-curl.txt
    '';
  };
  # TODO: add tests with tree-sitter-http packaged in nix
}
