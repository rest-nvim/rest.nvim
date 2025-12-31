{ self }: final: prev: let
  luaPackages-override = luaself: luaprev: {
    tree-sitter-http = luaself.callPackage ./tree-sitter-http.nix {};
    base64 = luaself.callPackage ({
      buildLuarocksPackage,
      fetchurl,
      fetchzip,
      luaOlder,
    }:
      buildLuarocksPackage {
        pname = "base64";
        version = "1.5-3";
        knownRockspec = (fetchurl {
          url    = "mirror://luarocks/base64-1.5-3.rockspec";
          sha256 = "sha256-jMWugDDJMOfapPyEWVrC2frF24MSr8pLsNtwK9ejLwM=";
        }).outPath;
        src = fetchzip {
          url    = "https://github.com/iskolbin/lbase64/archive/c261320edbdf82c16409d893a96c28c704aa0ab8.zip";
          sha256 = "sha256-Ucu7pxEbyeUyV12+FeFbGNhXiKsGYlXFMrb1Vhsnfrc=";
        };
        disabled = luaOlder "5.1";
      }) {};
    md5 = luaself.callPackage ({
      buildLuarocksPackage,
      fetchurl,
      fetchzip,
      luaOlder,
    }:
      buildLuarocksPackage {
        pname = "md5";
        version = "1.3-1";
        knownRockspec = (fetchurl {
          url    = "mirror://luarocks/md5-1.3-1.rockspec";
          sha256 = "sha256-2S6Dvk0yazW8DCJf2DYxrLW11+B7r6DCJZ7CMCMAfSI=";
        }).outPath;
        src = fetchzip {
          url    = "https://github.com/lunarmodules/md5/archive/refs/tags/1.3.zip";
          sha256 = "sha256-mCN7mmCGf2vdXriT1q8rrhUmKh49AY8A+cZVCu6XJzY=";
        };
        disabled = luaOlder "5.0";
      }) {};
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
          base64
          md5
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
