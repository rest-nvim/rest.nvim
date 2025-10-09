{
  self,
  inputs,
}: final: prev: let
  mkNeorocksTest = name: nvim:
    with final; neorocksTest {
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
          final.lua51Packages.base64
          final.lua51Packages.md5
          final.lua51Packages.tree-sitter-http
        ];
      extraPackages = [
        jq
      ];

      preCheck = ''
        # Neovim expects to be able to create log files, etc.
        export HOME=$(realpath .)
        export TREE_SITTER_HTTP_PLUGIN_DIR=${final.tree-sitter-http-plugin}
        export REST_NVIM_PLUGIN_DIR=${final.rest-nvim-dev}
      '';
    };
in {
  docgen = final.writeShellApplication {
    name = "docgen";
    runtimeInputs = [
      inputs.vimcats.packages.${final.system}.default
    ];
    text = /* bash */ ''
      mkdir -p doc
      vimcats lua/rest-nvim/{init,commands,autocmds,config/init,ui/highlights}.lua > doc/rest-nvim.txt
      vimcats lua/rest-nvim/{api,client/init,parser/init,script/init,cookie_jar,utils,logger}.lua > doc/rest-nvim-api.txt
      vimcats lua/rest-nvim/client/curl/{cli,utils}.lua > doc/rest-nvim-client-curl.txt
    '';
  };
  sync-readme = final.writeShellApplication {
    name = "sync-readme";
    text = /* bash */ ''
      set -e

      default=lua/rest-nvim/config/default.lua

      # Create a temporary file for the copied snippet
      snippet=$(mktemp)
      echo "1. Extract the config snippet from $default"
      sed -n '/default-config:start/,/default-config:end/ {
        /default-config:start/d
        /default-config:end/d
        p
      }' "$default" > "$snippet"

      echo '2. Build new README content'
      # Create a temporary file for the updated README.
      tmpfile=$(mktemp)

      echo '2-1. Print all lines up to the starting marker'
      sed '/default-config:start/q' README.md > "$tmpfile"

      echo '2-2. Append the new code block'
      {
        echo '```lua'
        cat "$snippet"
        echo '```'
      } >> "$tmpfile"

      echo '2-3. Append the rest of the README starting from the ending marker'
      sed -n '/default-config:end/,$p' README.md >> "$tmpfile"

      echo '3. Replace the old README with the new version'
      mv "$tmpfile" README.md

      rm "$snippet"

      echo "README.md updated successfully."
    '';
  };
  integration-stable = mkNeorocksTest "integration-stable" final.neovim;
  integration-nightly = mkNeorocksTest "integration-nightly" final.neovim-nightly;
}
