# generated with `nix run nixpkgs#luarocks-nix -- nix tree-sitter-http` command
# NOTE: added `tree-sitter` as input
{ buildLuarocksPackage, fetchurl, fetchzip, luaOlder, luarocks-build-treesitter-parser, tree-sitter }:
buildLuarocksPackage {
  pname = "tree-sitter-http";
  version = "0.0.35-1";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/tree-sitter-http-0.0.35-1.rockspec";
    sha256 = "0zhirssh356lj20fyzp058iqs0ss8b39spwd12mf4n2c1h91rzh2";
  }).outPath;
  src = fetchzip {
    url    = "https://github.com/rest-nvim/tree-sitter-http/archive/77ecf6385f1b5d422e0bbd12204374d287d61ad2.zip";
    sha256 = "018wzazajc1ma9lbd61sd6vkq11nmkhqwxjhrm7pmsf3g6sycg7x";
  };

  disabled = luaOlder "5.1";
  nativeBuildInputs = [ luarocks-build-treesitter-parser ];

  meta = {
    homepage = "https://github.com/rest-nvim/tree-sitter-http";
    description = "tree-sitter parser for http";
    license.fullName = "UNKNOWN";
  };
  # NOTE: properties below are copied from neotest-haskell repository.
  # required to successfully build tree-sitter parser
  preBuild = ''
    export HOME=$(mktemp -d)
  '';
  buildInputs = [
    tree-sitter
  ];
  propagatedBuildInputs = [luarocks-build-treesitter-parser];
}
