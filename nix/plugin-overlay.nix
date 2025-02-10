{ self }: final: prev: let
  luaPackages-override = luaself: luaprev: {
    tree-sitter-http = luaself.callPackage ./tree-sitter-http.nix {};
    rest-nvim = luaself.callPackage ({
      buildLuarocksPackage,
      fetchurl,
      fetchzip,
      luaOlder,
    }:
      buildLuarocksPackage {
        pname = "rest.nvim";
        version = "scm-1";
        knownRockspec = "${self}/rest.nvim-scm-1.rockspec";
        src = self;

        disabled = luaOlder "5.1";
        propagatedBuildInputs = with luaself; [
          nvim-nio
          mimetypes
          xml2lua
          fidget-nvim
          tree-sitter-http
        ];
      }) {};
  };
  tree-sitter-http-plugin = final.neovimUtils.buildNeovimPlugin {
    luaAttr = final.lua51Packages.tree-sitter-http;
  };
  rest-nvim-dev = final.neovimUtils.buildNeovimPlugin {
    luaAttr = final.lua51Packages.rest-nvim;
  };
in {
  lua5_1 = prev.lua5_1.override {
    packageOverrides = luaPackages-override;
  };
  lua51Packages = prev.lua51Packages // final.lua5_1.pkgs;
  inherit tree-sitter-http-plugin;
  inherit rest-nvim-dev;
}
