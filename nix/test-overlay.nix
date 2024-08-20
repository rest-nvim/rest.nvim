{
  self,
  inputs,
}: final: prev: let
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
  inherit docgen;
}
