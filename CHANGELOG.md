# Changelog

## [3.8.0](https://github.com/rest-nvim/rest.nvim/compare/v3.7.0...v3.8.0) (2024-09-20)


### Features

* allow custom dynamic variables without `$` prefix ([359d089](https://github.com/rest-nvim/rest.nvim/commit/359d089e822c553312d634d1572b2225b800e4a8))
* expand variables inside external body (fix [#455](https://github.com/rest-nvim/rest.nvim/issues/455)) ([97cc922](https://github.com/rest-nvim/rest.nvim/commit/97cc9224993387510e7b4a9cfff2b6b9bfb54bd6))


### Bug Fixes

* remove unrecognized option check (close [#461](https://github.com/rest-nvim/rest.nvim/issues/461)) ([6a7c193](https://github.com/rest-nvim/rest.nvim/commit/6a7c193c2b5f030d085544e58b36f2e7413e1728))

## [3.7.0](https://github.com/rest-nvim/rest.nvim/compare/v3.6.2...v3.7.0) (2024-09-14)


### Features

* remove env file extension validation ([6edb8fd](https://github.com/rest-nvim/rest.nvim/commit/6edb8fdb8c03ac9dcfce2b6dae09ab8c6f0f7ba4))


### Bug Fixes

* **ui:** always use `rest_nvim_result` filetype ([3bf17a2](https://github.com/rest-nvim/rest.nvim/commit/3bf17a2a955853d865feb9e2f0e6f3addf17acaa))

## [3.6.2](https://github.com/rest-nvim/rest.nvim/compare/v3.6.1...v3.6.2) (2024-09-12)


### Bug Fixes

* add logs & limits to dotenv module ([#456](https://github.com/rest-nvim/rest.nvim/issues/456)) ([ec8cbb2](https://github.com/rest-nvim/rest.nvim/commit/ec8cbb26eea517c0b32f7ac85341d8842e536db9))

## [3.6.1](https://github.com/rest-nvim/rest.nvim/compare/v3.6.0...v3.6.1) (2024-09-11)


### Bug Fixes

* don't encode `@` character (fix [#453](https://github.com/rest-nvim/rest.nvim/issues/453)) ([48fe19c](https://github.com/rest-nvim/rest.nvim/commit/48fe19c9c1e291d11fb2aa9608ea11ef9a8aa5dc))

## [3.6.0](https://github.com/rest-nvim/rest.nvim/compare/v3.5.1...v3.6.0) (2024-09-08)


### Features

* save response to file (close [#359](https://github.com/rest-nvim/rest.nvim/issues/359)) ([f9a5ebb](https://github.com/rest-nvim/rest.nvim/commit/f9a5ebbad35481343ea8b3a578bc30c00beb45e4))


### Bug Fixes

* force delete scratch buffer ([34f3fe9](https://github.com/rest-nvim/rest.nvim/commit/34f3fe9660b912429279ba87ab49aa3d0c37e0c9))

## [3.5.1](https://github.com/rest-nvim/rest.nvim/compare/v3.5.0...v3.5.1) (2024-09-05)


### Bug Fixes

* scope and buf number in setting options ([252d56a](https://github.com/rest-nvim/rest.nvim/commit/252d56a7334838e2406ebd58f780e3d9becfbf73))

## [3.5.0](https://github.com/rest-nvim/rest.nvim/compare/v3.4.0...v3.5.0) (2024-09-04)


### Features

* graphql support ([#433](https://github.com/rest-nvim/rest.nvim/issues/433)) ([91a9293](https://github.com/rest-nvim/rest.nvim/commit/91a929305f910b49b9c1d2f250585ec87e59c076))
* **ui:** show if response body is formatted ([3030841](https://github.com/rest-nvim/rest.nvim/commit/3030841e97f4e017930a874c9482db82567f49c4))


### Bug Fixes

* expand variables in graphql ([d3acfb5](https://github.com/rest-nvim/rest.nvim/commit/d3acfb524290f297542233e66c4241decaa97d38))
* **gq:** catch error while setting filetype ([b08b2c2](https://github.com/rest-nvim/rest.nvim/commit/b08b2c23480a8c760cdf1863f9debedb0ed369ea))

## [3.4.0](https://github.com/rest-nvim/rest.nvim/compare/v3.3.4...v3.4.0) (2024-09-03)


### Features

* **curl:** add opt-in option to add `--compressed` ([96a3a15](https://github.com/rest-nvim/rest.nvim/commit/96a3a153e8cffe69b7ac7d4923809749e9ba7079))
* use curl --compressed argument if Accept-Encoding includes gzip ([6822112](https://github.com/rest-nvim/rest.nvim/commit/6822112d719b0f28168efc89bfe7da094101eff9))

## [3.3.4](https://github.com/rest-nvim/rest.nvim/compare/v3.3.3...v3.3.4) (2024-09-03)


### Bug Fixes

* use lua stdlib in scripts (fix [#437](https://github.com/rest-nvim/rest.nvim/issues/437)) ([08f8d02](https://github.com/rest-nvim/rest.nvim/commit/08f8d0298228076a5155f9b76051e0e88a2aac3a))

## [3.3.3](https://github.com/rest-nvim/rest.nvim/compare/v3.3.2...v3.3.3) (2024-09-02)


### Bug Fixes

* **cookie:** `clean()` should keep cookies (fix [#434](https://github.com/rest-nvim/rest.nvim/issues/434)) ([e2f13a2](https://github.com/rest-nvim/rest.nvim/commit/e2f13a2705b9e5d698b0d868678a4eecd9e9305e))

## [3.3.2](https://github.com/rest-nvim/rest.nvim/compare/v3.3.1...v3.3.2) (2024-09-01)


### Reverts

* "fix(ui): use `rest_nvim_result` filetype for all panes (fix [#424](https://github.com/rest-nvim/rest.nvim/issues/424))" ([4044d85](https://github.com/rest-nvim/rest.nvim/commit/4044d85131506ccea433ea037ac44e2ce9a9e5f5))

## [3.3.1](https://github.com/rest-nvim/rest.nvim/compare/v3.3.0...v3.3.1) (2024-09-01)


### Bug Fixes

* **ui:** use `rest_nvim_result` filetype for all panes (fix [#424](https://github.com/rest-nvim/rest.nvim/issues/424)) ([3327656](https://github.com/rest-nvim/rest.nvim/commit/33276565fd6320411734888484adf8d54ac315ca))

## [3.3.0](https://github.com/rest-nvim/rest.nvim/compare/v3.2.1...v3.3.0) (2024-09-01)


### Features

* prompt variables (close [#238](https://github.com/rest-nvim/rest.nvim/issues/238)) ([0438864](https://github.com/rest-nvim/rest.nvim/commit/043886421e97dc9c74539c371164849c6c5af902))


### Bug Fixes

* handle input cancel ([5ce671e](https://github.com/rest-nvim/rest.nvim/commit/5ce671e06b349c55e22a6841a33cf20347413ea5))

## [3.2.1](https://github.com/rest-nvim/rest.nvim/compare/v3.2.0...v3.2.1) (2024-08-30)


### Bug Fixes

* **statistics:** allow all curl statistics, ordering, highlight ([344fdff](https://github.com/rest-nvim/rest.nvim/commit/344fdffb11493edbcf6f9932fd98d8ca4df79928))
* **statistics:** change statistics option to list ([6fc08c9](https://github.com/rest-nvim/rest.nvim/commit/6fc08c9020028ad6a53af48833a428a3d9109489))
* **statistics:** fix skip curl.statistics key ([1eb44cd](https://github.com/rest-nvim/rest.nvim/commit/1eb44cd33b8e51424f001f4050aeec86a1b2ccd2))

## [3.2.0](https://github.com/rest-nvim/rest.nvim/compare/v3.1.0...v3.2.0) (2024-08-26)


### Features

* command-modifiers in more subcommands (fix [#419](https://github.com/rest-nvim/rest.nvim/issues/419)) ([75c4856](https://github.com/rest-nvim/rest.nvim/commit/75c485647979963bcbd6cc5c16fcd4bcffdf83d6))


### Bug Fixes

* check if last request exist before running `:Rest last` ([311e7da](https://github.com/rest-nvim/rest.nvim/commit/311e7da6900d5c8b3901526c70903ea85d7e80e1))
* **parser:** handle variables in URI ([2402414](https://github.com/rest-nvim/rest.nvim/commit/2402414aeb270b09f6f218d59246450c97c19ab3))
* **utils:** skip lsp formatexpr ([#414](https://github.com/rest-nvim/rest.nvim/issues/414)) ([b7ab923](https://github.com/rest-nvim/rest.nvim/commit/b7ab923cd1940715c3dc9899c4e07b92af9ef115))

## [3.1.0](https://github.com/rest-nvim/rest.nvim/compare/v3.0.3...v3.1.0) (2024-08-25)


### Features

* use float titles for help UI (fix [#291](https://github.com/rest-nvim/rest.nvim/issues/291)) ([fafa283](https://github.com/rest-nvim/rest.nvim/commit/fafa2830c469bb0ee8fad6bd1101a1560de2cea2))

## [3.0.3](https://github.com/rest-nvim/rest.nvim/compare/v3.0.2...v3.0.3) (2024-08-23)


### Bug Fixes

* neovim v0.10.1 compatibility (fix [#408](https://github.com/rest-nvim/rest.nvim/issues/408)) ([7e7dcfc](https://github.com/rest-nvim/rest.nvim/commit/7e7dcfce195d67057822797f434d6e26ce00ee03))
* **queries:** update queries ([e51fff1](https://github.com/rest-nvim/rest.nvim/commit/e51fff10f0659c141e0e91221b1f019a5ced3745))

## [3.0.2](https://github.com/rest-nvim/rest.nvim/compare/v3.0.1...v3.0.2) (2024-08-22)


### Bug Fixes

* remove tree-sitter-http from github workflow ([0c3700c](https://github.com/rest-nvim/rest.nvim/commit/0c3700c5b86a7e991c74adc617804cb183da4fec))

## [3.0.1](https://github.com/rest-nvim/rest.nvim/compare/v3.0.0...v3.0.1) (2024-08-22)


### Bug Fixes

* manually run release-please ([05fe751](https://github.com/rest-nvim/rest.nvim/commit/05fe751014574dfae71c5f5331027681f7dbbb60))

## [3.0.0](https://github.com/rest-nvim/rest.nvim/compare/v2.0.1...v3.0.0) (2024-08-22)


### ⚠ BREAKING CHANGES

* format to indent-size 4
* **script:** modularize script runner client
* **config:** rewrite config structures
* **config:** rewrite configs
* big rewrite
* add archiving notice

### ref

* **config:** rewrite config structures ([6583234](https://github.com/rest-nvim/rest.nvim/commit/65832343cbc1b73330891e30132e8a0af477aa9a))
* **script:** modularize script runner client ([c6173ec](https://github.com/rest-nvim/rest.nvim/commit/c6173ecaeff0000e8143a2d02e6867899e331b94))


### Features

* add `tree-sitter-http` submodule ([76d868c](https://github.com/rest-nvim/rest.nvim/commit/76d868c106446c8db46533e39293e15b14405025))
* add nix. I have no idea what I'm doing but it works ([434927d](https://github.com/rest-nvim/rest.nvim/commit/434927d6234783718531e54f71873c5047a865a1))
* automatically name request by file name ([ff9cf3d](https://github.com/rest-nvim/rest.nvim/commit/ff9cf3dd21fe02a83c82fd81a77e8ae1db1d7602))
* basic `:Rest curl` command ([6a7699b](https://github.com/rest-nvim/rest.nvim/commit/6a7699bae02caf5bc98e229fd1216aa16a3e7bb3))
* better progress handlers ([27d0faf](https://github.com/rest-nvim/rest.nvim/commit/27d0faf4458a788badf3bb2e054ec34783192484))
* bump version of tree-sitter-http parser ([6ab4cb0](https://github.com/rest-nvim/rest.nvim/commit/6ab4cb0f9667eeca3e7fa0d067454b2ce78655c2))
* client selector & libcurl client ([bf41cbf](https://github.com/rest-nvim/rest.nvim/commit/bf41cbf07b1fb8b2883641728942d1920216ac99))
* **commands:** `:Rest cookies` ([ee05dc5](https://github.com/rest-nvim/rest.nvim/commit/ee05dc503353df8deac223ddf81c893b1e5ba3e7))
* **commands:** `:Rest open` ([0fbef12](https://github.com/rest-nvim/rest.nvim/commit/0fbef1276e58f223a68c2c6edce068222d5b329b))
* **commands:** use command-modifiers like `:tab` ([ce55212](https://github.com/rest-nvim/rest.nvim/commit/ce552128f21b1ea2dfaafa7b9480b1e855d0340a))
* **config:** ensure all options are working ([0aa1c42](https://github.com/rest-nvim/rest.nvim/commit/0aa1c422d18ed77eeffe0cc9191e4622641465c6))
* **config:** more builtin request hooks ([5880134](https://github.com/rest-nvim/rest.nvim/commit/58801349da987d6a1d02f36e30c5f4563e3c5268))
* cookies ([611450a](https://github.com/rest-nvim/rest.nvim/commit/611450a38a81f64bd1334b8b6a909b762f6790be))
* **curl.cli:** basic body support ([3200046](https://github.com/rest-nvim/rest.nvim/commit/3200046f9400245907f832905b5afd33391b5f2d))
* **curl.cli:** parse statistics ([306975a](https://github.com/rest-nvim/rest.nvim/commit/306975ae2cb9b15c7f34cfc346220075660aa629))
* custom mappings for result window ([8f62a29](https://github.com/rest-nvim/rest.nvim/commit/8f62a290be397a1e4a2778330f026f731251f197))
* delete unused `syntax/` and `tests/` dir ([e62fcc1](https://github.com/rest-nvim/rest.nvim/commit/e62fcc18dc8b80f7b30885114e4b34c720e9c655))
* **dotenv:** auto-register matching dotenv file ([025c9d4](https://github.com/rest-nvim/rest.nvim/commit/025c9d4127905b7fa8e8929ba41222a27123b2f2))
* evaluate context sequentially ([95f810a](https://github.com/rest-nvim/rest.nvim/commit/95f810a71091b6f62c5a8f5eef391b2d84e8dce4))
* external body support ([51d115e](https://github.com/rest-nvim/rest.nvim/commit/51d115e49b699de5d48b7052ad4577d93183d378))
* **ftplugin:** remove `n:&gt;` from `'comments'` ([968c15b](https://github.com/rest-nvim/rest.nvim/commit/968c15bc101c2138009997aa387e7ea69915b085))
* get rid of `_G` usage ([16ba718](https://github.com/rest-nvim/rest.nvim/commit/16ba7185adcfa12306344ee6de7de1558e12334e))
* guess content-type for external bodies ([7c100f2](https://github.com/rest-nvim/rest.nvim/commit/7c100f2ccedf4ae7a0bacd401c339b78ec2f7ea6))
* handler script support ([e721684](https://github.com/rest-nvim/rest.nvim/commit/e721684b759e8acc5c5b23885b6155d8356d3e9c))
* lazy-loading & global user commands ([47beb74](https://github.com/rest-nvim/rest.nvim/commit/47beb74b22f3602ebb13060bb1a05c21a72801c4))
* parse & render status text ([100626e](https://github.com/rest-nvim/rest.nvim/commit/100626e21c48988f163b3b957f0f275e215896bf))
* pre-script & handler-scripts ([2fec5f9](https://github.com/rest-nvim/rest.nvim/commit/2fec5f9d6c3549eebff7adcdeb0e82fbe0a118a7))
* print request name, url, and version in UI ([01c661b](https://github.com/rest-nvim/rest.nvim/commit/01c661b185a5876c8ee3ff5e5dcd162e66a41461))
* **queries:** add empty `fold.scm` to enable fold ([3a18c92](https://github.com/rest-nvim/rest.nvim/commit/3a18c927baa9cc2f0e3d5605b644f126d4ba273a))
* remove external formatter, use `gq` instead ([1741ed8](https://github.com/rest-nvim/rest.nvim/commit/1741ed8f6cb94c019b2a584477275a7e92ba80a0))
* run request by name ([70eefb5](https://github.com/rest-nvim/rest.nvim/commit/70eefb5e843adcc030dd0878fb8921b1bae2f99c))
* separate context from request object ([1e92829](https://github.com/rest-nvim/rest.nvim/commit/1e928294ed6b2e752f0d4c4238dacd68d887913b))
* set concealcursor to `nc` on help window ([3af7b3e](https://github.com/rest-nvim/rest.nvim/commit/3af7b3e99b7e60760a123501e13037d2b161b729))
* treat form-urlencoded as raw-body ([90c46f7](https://github.com/rest-nvim/rest.nvim/commit/90c46f700edd05974714e8cc9ab92cc65a240719))
* **ts:** match queries to v3 parser version ([c15b81f](https://github.com/rest-nvim/rest.nvim/commit/c15b81f63b7cf66fa61467ab1af6e166fa2df01c))
* upgrade `tree-sitter-http` ([a9040da](https://github.com/rest-nvim/rest.nvim/commit/a9040da711ed5bad50009ccbe580f7cd9e7fac17))


### Bug Fixes

* `rest-nvim.result` is removed ([78ad115](https://github.com/rest-nvim/rest.nvim/commit/78ad1152ea4b1f9eaeec066453ac76dc06cd8c40))
* allow to abort `:Rest env select` command ([2f04e29](https://github.com/rest-nvim/rest.nvim/commit/2f04e293794d991f774006e7a1c6b896171d28fe))
* **build:** proper require for luarocks.nvim breaking changes ([5300ae0](https://github.com/rest-nvim/rest.nvim/commit/5300ae0b111dbee1322949a197cc424eac6b849f))
* case-insensitive header ([fc9b1f6](https://github.com/rest-nvim/rest.nvim/commit/fc9b1f65d695a012475d5634415be296b1fb7ffe))
* change default HL behavior ([31a5665](https://github.com/rest-nvim/rest.nvim/commit/31a56656f374625c012ff0c411da1593e7c8cd8a))
* **commands:** complete on command with mods ([c3ff445](https://github.com/rest-nvim/rest.nvim/commit/c3ff445bdf8b6919f35eb206e6a461c2106a58f6))
* **config:** require loop ([9346bcc](https://github.com/rest-nvim/rest.nvim/commit/9346bcc0c9210e1cceda8ecd3633ee5be388b84f))
* correctly urlencode query parameters (fixes [#317](https://github.com/rest-nvim/rest.nvim/issues/317)) ([38ceda9](https://github.com/rest-nvim/rest.nvim/commit/38ceda9bc3e4dc17aa67dcd1a17829e0d3c2334b))
* don't conceal result pane ([2737024](https://github.com/rest-nvim/rest.nvim/commit/273702404e838ae9fc9e3427918170263ecbb1d4))
* don't try to highlight over the last line ([826118b](https://github.com/rest-nvim/rest.nvim/commit/826118b5bc47d0ba179c8261b824c4783d66d7eb))
* enable fold in result UI ([cbe31e7](https://github.com/rest-nvim/rest.nvim/commit/cbe31e724c1837b7ff865956f693f150e37e9892))
* **functions:** handle highlights of winbar result with prefixed zeros ([1bad966](https://github.com/rest-nvim/rest.nvim/commit/1bad966117230e173e31f503c9718f9eb145388f))
* H and L keymaps are buffer local ([21a9ae3](https://github.com/rest-nvim/rest.nvim/commit/21a9ae3e48d188df5330c14dda40e8f6244eac68))
* handle `HOST` header ([828cf52](https://github.com/rest-nvim/rest.nvim/commit/828cf521cd2b915bef22040c02c611d3f1771040))
* handle multiple space between command args ([5dc89bb](https://github.com/rest-nvim/rest.nvim/commit/5dc89bbed213345282457f677df48752696aa263))
* **health:** recommend using the `--lua-version` flag in luarocks commands ([9b9ad65](https://github.com/rest-nvim/rest.nvim/commit/9b9ad6529d4026c4a18b23c60c6d6923c8109bb3))
* injection queries ([58e8bca](https://github.com/rest-nvim/rest.nvim/commit/58e8bca41ac29b9717a0bf00307fbe67d393979a))
* match lowercase content-type header ([20c5b52](https://github.com/rest-nvim/rest.nvim/commit/20c5b5259afa7f4867474cc463211d64c93ba371))
* minor issues ([0258236](https://github.com/rest-nvim/rest.nvim/commit/0258236adad8b98f2b5acb35040b4c9ce3593311))
* minor issues ([ec41cec](https://github.com/rest-nvim/rest.nvim/commit/ec41cec7af68f945130265f322fc7b3157c16dff))
* minor issues ([c2d41e5](https://github.com/rest-nvim/rest.nvim/commit/c2d41e507ab1942e0f21c5a1e27d1017e425ca00))
* minor type issues ([7ab1007](https://github.com/rest-nvim/rest.nvim/commit/7ab100700b5e8766d8b8e888b60f4f9ec4dba6a1))
* **parser:** handle reqeust name from comment ([fed6d4a](https://github.com/rest-nvim/rest.nvim/commit/fed6d4a78877a60ff8de31d9a844df9e55eefe06))
* **parser:** handler heading without value ([e795f7c](https://github.com/rest-nvim/rest.nvim/commit/e795f7c93bbaed84ac977d491aef8ef2aae60dd5))
* **parser:** remove line breaks from url ([6af0022](https://github.com/rest-nvim/rest.nvim/commit/6af002292969a5b6c92fc7d17824a8e8028dc770))
* **parser:** set host based on header of strings ([f01fb8e](https://github.com/rest-nvim/rest.nvim/commit/f01fb8e0679e7447acd1ccb427523e3912f9a7d4))
* pre-request script sets variable locally ([c2e7ab4](https://github.com/rest-nvim/rest.nvim/commit/c2e7ab4170197aa7d550f91c01ad30ab620d3c3a))
* response buffer fold issue ([7fbc292](https://github.com/rest-nvim/rest.nvim/commit/7fbc292f72bce3b1895ff18e6b3d531d3af6edb5))
* **run last:** not modify body in order to use it again ([9598c89](https://github.com/rest-nvim/rest.nvim/commit/9598c893ac8e6aee2e3e0dc526f2c44bc4889ba9))
* set host in the context of port ([3c13242](https://github.com/rest-nvim/rest.nvim/commit/3c132425239dd35ce97dbdd1fe0a7f8aa75cb30c))
* **test:** don't run real request on test ([2b61cec](https://github.com/rest-nvim/rest.nvim/commit/2b61cec012ad678fde7f41084677482a69a04e0b))
* **test:** issues from different machine ([e04f2c9](https://github.com/rest-nvim/rest.nvim/commit/e04f2c923d294bb6427dfa31b0f94ed766cdf27b))
* **ui.panes:** handle unloaded buffer ([a88b0f8](https://github.com/rest-nvim/rest.nvim/commit/a88b0f8afdf06ca7382fd6a252dd66cb96d5b741))
* **ui:** don't try to render image ([061f65d](https://github.com/rest-nvim/rest.nvim/commit/061f65d1305ee0630de1c7a5033263c8f259c58d))
* **ui:** handle when content-type is not provided ([b8a1bf8](https://github.com/rest-nvim/rest.nvim/commit/b8a1bf8335248058fdefecec0c958789d99ed954))
* **ui:** http_version comes before code ([377ad65](https://github.com/rest-nvim/rest.nvim/commit/377ad65877cc972aa2be3fe0cc793f2fe19d9c96))
* use `title` field instead of manual prefix ([7d1058f](https://github.com/rest-nvim/rest.nvim/commit/7d1058ffe312117515c98a269e779af6571cb817))
* use `vim.notify` instead of `logger` ([09358a3](https://github.com/rest-nvim/rest.nvim/commit/09358a3afc94d24f3bd84d67d92072755d5f1b83))


### Documentation

* add archiving notice ([e7843c5](https://github.com/rest-nvim/rest.nvim/commit/e7843c55f9df6a9db9f97dac180035c6ff895a90))


### Styles

* format to indent-size 4 ([8369aa1](https://github.com/rest-nvim/rest.nvim/commit/8369aa1a535fd1b30ebe195e0927649aa8a54494))


### Code Refactoring

* big rewrite ([f16b420](https://github.com/rest-nvim/rest.nvim/commit/f16b4208bda93bc5f3e13cb3c2c16af91aa5dc37))
* **config:** rewrite configs ([a6cf82b](https://github.com/rest-nvim/rest.nvim/commit/a6cf82be777d0aea5878c6c31023489f0ff51202))

## [2.0.1](https://github.com/rest-nvim/rest.nvim/compare/v2.0.0...v2.0.1) (2024-03-19)


### Bug Fixes

* **config:** proper checking for the keybinds configuration table correctness, see [#306](https://github.com/rest-nvim/rest.nvim/issues/306) ([0277464](https://github.com/rest-nvim/rest.nvim/commit/0277464a9ca9707029f8d04aa14407a8b3239ef1))
* ensure help window width is an int ([af7b2ea](https://github.com/rest-nvim/rest.nvim/commit/af7b2ead485f6c88199e9c3e0bf551555a9a7fb6))
* **functions:** proper env variables file loading order, fixes [#308](https://github.com/rest-nvim/rest.nvim/issues/308) ([2030bf6](https://github.com/rest-nvim/rest.nvim/commit/2030bf65a4a91b08de95b3bd0e753050d1066b53))
* **health:** include `luarocks.nvim` plugin in the luarocks installation section ([eff6f1b](https://github.com/rest-nvim/rest.nvim/commit/eff6f1bef97e983f09abc1bb0b22a53c9298db9f))
* **parser:** make `parse_request` handle `request` TS nodes ([a74e940](https://github.com/rest-nvim/rest.nvim/commit/a74e940a8bab560f280f2bb7c822e4087e19dc8f))
* **plugin:** improve log message when a dependency was not found ([abfc4b2](https://github.com/rest-nvim/rest.nvim/commit/abfc4b24270bb10e1468e14d73cadd16570de2f3))

## [2.0.0](https://github.com/rest-nvim/rest.nvim/compare/v1.2.1...v2.0.0) (2024-03-18)


### ⚠ BREAKING CHANGES

* release v2, it's finally here :)
* **parser:** do not read environment files during the parsing process

### ref

* **parser:** do not read environment files during the parsing process ([5c34314](https://github.com/rest-nvim/rest.nvim/commit/5c34314cdc086a8a068458b68e752325980fb37f))


### Features

* **config:** add `decode_url` configuration option to the `result.behavior` table ([070660b](https://github.com/rest-nvim/rest.nvim/commit/070660bfe00d06d4ba01434be12e666860175985))
* **curl:** encode URL query parameters using cURL flags ([16284ba](https://github.com/rest-nvim/rest.nvim/commit/16284ba6c127c4bfa0468b3e9406595d93fe1a48))
* **env_vars:** add a `quiet` parameter to `read_file` to decide whether to fail silently if an environment file is not found, some cleanups ([ee3f047](https://github.com/rest-nvim/rest.nvim/commit/ee3f047a34961b4fbf203559253578dadfc1a31b))
* re-implement pre and post request hooks, load env variables from environment file before running the requests ([b8cfe07](https://github.com/rest-nvim/rest.nvim/commit/b8cfe071ede11988d19c785d9cccc8bf721aab06))
* release v2, it's finally here :) ([72e2662](https://github.com/rest-nvim/rest.nvim/commit/72e2662b380049f200ca81d9ff1b5a082e97913f))
* **utils:** expose a `escape` function to encode strings, meant to be used by extensions to encode URLs in case their clients does not provide an encode utility ([c3dca4a](https://github.com/rest-nvim/rest.nvim/commit/c3dca4ac73269f5bf8b8be7a424b8eea640da159))

## [1.1.0](https://github.com/rest-nvim/rest.nvim/compare/v1.0.1...v1.1.0) (2024-02-12)


### Features

* add Lualine component ([#279](https://github.com/rest-nvim/rest.nvim/issues/279)) ([3e0d86d](https://github.com/rest-nvim/rest.nvim/commit/3e0d86d66db8858d7e847e7ad495274d6663c985))
* add telescope extension ([#278](https://github.com/rest-nvim/rest.nvim/issues/278)) ([de3c0fd](https://github.com/rest-nvim/rest.nvim/commit/de3c0fd6130def3dea2ef3809dfbf4458a0946fc))


### Bug Fixes

* add host before url only if it starts with '/', otherwise it probably starts with 'http' ([f3d319f](https://github.com/rest-nvim/rest.nvim/commit/f3d319f4567d253977217963c1910e83eeb8c0af))
* return non json body ([543b64c](https://github.com/rest-nvim/rest.nvim/commit/543b64cc639c01db319f00ba6a2b0767d0c8e8c1))
* **telescope:** doc and check select is nil ([e862e72](https://github.com/rest-nvim/rest.nvim/commit/e862e725ba483b8c48585b44738767c86668d49e))

## [1.0.1](https://github.com/rest-nvim/rest.nvim/compare/v1.0.0...v1.0.1) (2024-01-24)


### Bug Fixes

* **ci:** run luarocks CI on new releases too and let us run the CI manually ([6ce1f76](https://github.com/rest-nvim/rest.nvim/commit/6ce1f763247fb218ecf0fba749145c9688797afa))

## 1.0.0 (2023-11-29)


### Features

* add callbacks ([dcea003](https://github.com/rest-nvim/rest.nvim/commit/dcea003675f4bb2445276654c89ea3d5f335cd26))
* add config option for custom dynamic variables ([3da902d](https://github.com/rest-nvim/rest.nvim/commit/3da902dd2304a813eec321e6ff2bcf8e6c60ff7c))
* add config.show_curl_command ([aea7c64](https://github.com/rest-nvim/rest.nvim/commit/aea7c64bdff1073beed9bd7fddb60cce7796d7ff))
* add formatting CI so I don't have to care about formatting myself ([28a146d](https://github.com/rest-nvim/rest.nvim/commit/28a146d73a29072ae915da490f8cf99650b19b7e))
* add luacheck (WIP) ([64eb52f](https://github.com/rest-nvim/rest.nvim/commit/64eb52fee8f0fc6a5f9b67f7d99cce67098b7e7a))
* add selene linter CI ([28eaf15](https://github.com/rest-nvim/rest.nvim/commit/28eaf15db2f74c11863a4663022db60f1a1f3945))
* add support for custom formatters ([b98ee9e](https://github.com/rest-nvim/rest.nvim/commit/b98ee9e7e3b0110c064903e81d2c2ed8b200013f))
* add support for passing flags to curl ([3c46649](https://github.com/rest-nvim/rest.nvim/commit/3c46649aa2fec8282518e0743eff9d8305193d42))
* add tree-sitter parser instructions, remove syntax highlighting lazy-loading. Closes [#30](https://github.com/rest-nvim/rest.nvim/issues/30) ([1831a5f](https://github.com/rest-nvim/rest.nvim/commit/1831a5faad9f76cf9cb2d1517b4719743abbcd20))
* add verbose command to preview cURL requests ([f04b205](https://github.com/rest-nvim/rest.nvim/commit/f04b2051e9594f1fe1538cf397cea68709e2ebd4))
* adding a RestLog command ([f1597ab](https://github.com/rest-nvim/rest.nvim/commit/f1597ab6df09b0f04196fa7d516a1b20c91f292e))
* adding rockspec ([f87117d](https://github.com/rest-nvim/rest.nvim/commit/f87117d6a0d5bee54832c6e2962c369061484655))
* allow selecting of env files with command ([090e253](https://github.com/rest-nvim/rest.nvim/commit/090e253c114b6d5448bac5869a28a6623c195e3a))
* allow skipping SSL verification, closes [#46](https://github.com/rest-nvim/rest.nvim/issues/46) ([#50](https://github.com/rest-nvim/rest.nvim/issues/50)) ([cd6815d](https://github.com/rest-nvim/rest.nvim/commit/cd6815d1a04021e0ff206fc02c3b67d2e06d8a44))
* apply `jq` formatting on any JSON content-type, see [#61](https://github.com/rest-nvim/rest.nvim/issues/61) ([155816b](https://github.com/rest-nvim/rest.nvim/commit/155816b52c1efa58a06c8c91d0339d32f1ed0e2e))
* be able to use environment variables in headers ([b44e602](https://github.com/rest-nvim/rest.nvim/commit/b44e602b9f94beb77573fc83b42dd55802c530d5))
* better syntax highlights in http result ([5b21f91](https://github.com/rest-nvim/rest.nvim/commit/5b21f91b462d224d6a2c2dc6cb74d1796dae20d0))
* **ci:** add releaser CI to automate semver ([e0ca3ef](https://github.com/rest-nvim/rest.nvim/commit/e0ca3ef7f567e9829997ad006f8b1c255fbf8773))
* config option for custom environment variables file ([#83](https://github.com/rest-nvim/rest.nvim/issues/83)) ([2542929](https://github.com/rest-nvim/rest.nvim/commit/254292969c7bb052d0123ceba5af0382cc4cb6c0))
* defer splicing as late as possible ([f811cfe](https://github.com/rest-nvim/rest.nvim/commit/f811cfebf830040f43edfec9604c56028ab2f7db))
* **doc:** use treesitter injection ([#243](https://github.com/rest-nvim/rest.nvim/issues/243)) ([8b62563](https://github.com/rest-nvim/rest.nvim/commit/8b62563cfb19ffe939a260504944c5975796a682))
* dont display binary output in answer ([5ebe35f](https://github.com/rest-nvim/rest.nvim/commit/5ebe35f4d1a0a841ef231e03ce446e884c1651bf))
* implement document vars, fix [#68](https://github.com/rest-nvim/rest.nvim/issues/68) ([7e45caf](https://github.com/rest-nvim/rest.nvim/commit/7e45cafe9c3d00cc40df80272a041c242f52b393))
* implementing backend-agnostic run_request ([87941ab](https://github.com/rest-nvim/rest.nvim/commit/87941abfc7096669d3283131a023ab1f387629d7))
* initial statistics implementation ([091d160](https://github.com/rest-nvim/rest.nvim/commit/091d16083092c8c8ee6033b8c35037a5b9a01e12))
* introduce a testing framework ([d34e1b8](https://github.com/rest-nvim/rest.nvim/commit/d34e1b80ad47fe8818dea179bd7562fb7472b0b3))
* introduce stringify_request ([7b21a36](https://github.com/rest-nvim/rest.nvim/commit/7b21a361982a5261f2eb187e8e99761a63f772cd))
* log failed request in logfile ([8373dcd](https://github.com/rest-nvim/rest.nvim/commit/8373dcd31338d42ec2b4d3975bdc6e07d9cf5937))
* make it possible to not inline external file ([248a07c](https://github.com/rest-nvim/rest.nvim/commit/248a07ca3f65c13417b66255c2a3bad1e8341827))
* move highlight option to per-query options ([09143ad](https://github.com/rest-nvim/rest.nvim/commit/09143adbef84b8376eb7a703f187cd5d058d15fa))
* refactor writing to buffer ([e326b56](https://github.com/rest-nvim/rest.nvim/commit/e326b5641ec94faf59db80553c82250bf1223b6f))
* running a response script to set env ([090e253](https://github.com/rest-nvim/rest.nvim/commit/090e253c114b6d5448bac5869a28a6623c195e3a))
* support variables in path towards the file to load as well ([ef06dae](https://github.com/rest-nvim/rest.nvim/commit/ef06daed22b992c3e0b6cbd017bd752c2c0eb1b2))
* update highlights query ([713ba63](https://github.com/rest-nvim/rest.nvim/commit/713ba63cb1d3be15a7aada3f65a3252c60c59383))
* update tree-sitter setup, http parser got merged into nvim-treesitter ([759bf5b](https://github.com/rest-nvim/rest.nvim/commit/759bf5b1a8cd15ecf6ecf2407a826d4be6ec3414))
* use size and time default transformers ([d60951c](https://github.com/rest-nvim/rest.nvim/commit/d60951c969170443be95b48cc57387a78501e211))
* yank executable curl cmd ([b635ff2](https://github.com/rest-nvim/rest.nvim/commit/b635ff2cfd3471b3b5b0dbb85121bc8ac94877c8))


### Bug Fixes

* `get_auth` was always returning nil ([d6aeecb](https://github.com/rest-nvim/rest.nvim/commit/d6aeecbae7229fa5f4f1e495a9b398140b807f53))
* 51: body_start is calculated correctly even if the last request has ([52448f5](https://github.com/rest-nvim/rest.nvim/commit/52448f50c7ff0ca1206e7e142cb204e9e4422290))
* add http highlights file to repository ([da70732](https://github.com/rest-nvim/rest.nvim/commit/da707323197c0b4c116a60c4799f59ba73d21dbf))
* add ignore http version ([383af39](https://github.com/rest-nvim/rest.nvim/commit/383af397082ec47310d0f074910f5465ffd0ecc7))
* **ci/formatter:** remove init.lua reference ([ca6ba49](https://github.com/rest-nvim/rest.nvim/commit/ca6ba49ad9dbe969436df75ba03c2dc30b0aea1f))
* **ci:** add missing stylua version field to formatter ([9515f59](https://github.com/rest-nvim/rest.nvim/commit/9515f597b9d31f2ccc4994fb1038ca81f0b476d6))
* **ci:** change linter job name to luacheck ([b971076](https://github.com/rest-nvim/rest.nvim/commit/b9710762747a9021bd8c029319d0e541f450692e))
* **curl:** check if `b:current_syntax` exists before trying to unlet it ([ad7ac9f](https://github.com/rest-nvim/rest.nvim/commit/ad7ac9fb765659b59349b66b390ac67727f6a295))
* **curl:** return a better error message, see [#16](https://github.com/rest-nvim/rest.nvim/issues/16) and [#17](https://github.com/rest-nvim/rest.nvim/issues/17) ([2ed39f1](https://github.com/rest-nvim/rest.nvim/commit/2ed39f16c565cd21542f51c9d148118d55f7ff8e))
* disable interpretation of backslash escapes in response body ([d5a4022](https://github.com/rest-nvim/rest.nvim/commit/d5a40221cbf9437e0542c36f62ed803bff65b311))
* disable interpretation of backslash escapes in response body rendering ([275c713](https://github.com/rest-nvim/rest.nvim/commit/275c713f1bf16f4c58462ef92a17e0fa20a245bd))
* document renamed variable ([6e73def](https://github.com/rest-nvim/rest.nvim/commit/6e73defb2ec6aeb4d4bf060f798277f58ebafa0f))
* env var interpolation regex expression ([#53](https://github.com/rest-nvim/rest.nvim/issues/53)) ([e0f023e](https://github.com/rest-nvim/rest.nvim/commit/e0f023e30c6b1267f15c1316ef2bd70fd7dae41c))
* error handling for formatters ([dc10994](https://github.com/rest-nvim/rest.nvim/commit/dc10994afe07f75aaf6ea9f1cb71c00d0e3a11f2))
* error when run_request is run without { verbose = XXX } ([25761da](https://github.com/rest-nvim/rest.nvim/commit/25761da6d7bbe16a7fcb2850d05ce1ccba53cfaf))
* escape single quotes in response body ([59d5331](https://github.com/rest-nvim/rest.nvim/commit/59d53311c8dc36ebe356bc74fc36ae402272a5cd))
* escape single quotes in response body ([da30eef](https://github.com/rest-nvim/rest.nvim/commit/da30eef5a13f5f0af0ed52d1ae4f2a609b1dd4f3))
* find next request line when the verb is 'DELETE' ([3ee124d](https://github.com/rest-nvim/rest.nvim/commit/3ee124d0b1de4bba25f5185a3b50828ac8743a97))
* formatter for html ([e5e364f](https://github.com/rest-nvim/rest.nvim/commit/e5e364f44489c660a1cbe1e7f97b0d7097e7988e))
* hardcoded lower casing of content-type ([17ab07d](https://github.com/rest-nvim/rest.nvim/commit/17ab07d72a3931718d88826253452d2fed0cdc3f)), closes [#157](https://github.com/rest-nvim/rest.nvim/issues/157)
* httpResultPath match ([#245](https://github.com/rest-nvim/rest.nvim/issues/245)) ([5bd5713](https://github.com/rest-nvim/rest.nvim/commit/5bd5713a8c261b3544039fc3ffb9cee04e8938d8))
* ignore commented lines as it should be ([0096462](https://github.com/rest-nvim/rest.nvim/commit/0096462d0f83f1e93f70ea65c55817403353820b))
* include documentation on rockspec ([c63c780](https://github.com/rest-nvim/rest.nvim/commit/c63c7807f834339c140dbdf014f0f3bec353cb17))
* inconsistency in rockspec ([8f0232b](https://github.com/rest-nvim/rest.nvim/commit/8f0232b674fffb7ba8380eca763442722582925e))
* **init:** squashed some luacheck errors ([d5a0b5e](https://github.com/rest-nvim/rest.nvim/commit/d5a0b5ec7a8571126e886cbc091f5f3b7cc20c7c))
* **log:** dont hardcode log level ([867cde3](https://github.com/rest-nvim/rest.nvim/commit/867cde3f6895dc9c81dffc8b99a6f51d1b61ed95))
* missing argument to end_request ([2826f69](https://github.com/rest-nvim/rest.nvim/commit/2826f6960fbd9adb1da9ff0d008aa2819d2d06b3)), closes [#94](https://github.com/rest-nvim/rest.nvim/issues/94)
* parsing of curl arguments ([48a7c85](https://github.com/rest-nvim/rest.nvim/commit/48a7c8564b8ee3e0eaafa094d911699d92a89a09))
* parsing of headers and json body ([88ff794](https://github.com/rest-nvim/rest.nvim/commit/88ff794eb323843e138fa75b7c30bb994ba4135f))
* parsing of nested tables in request body ([46441b6](https://github.com/rest-nvim/rest.nvim/commit/46441b631c398924b84e141940415947d1a6cb0b))
* proper comments parsing regex. Closes [#29](https://github.com/rest-nvim/rest.nvim/issues/29) ([fb35b85](https://github.com/rest-nvim/rest.nvim/commit/fb35b85bd8cca26c1bd807cf3af313b3fbcc6a86))
* proper regex for env variables and json body detecting ([850f01e](https://github.com/rest-nvim/rest.nvim/commit/850f01e6738affde079ed38d9b52484e2100ad4a))
* proper search regex for json body start/end ([2d970d0](https://github.com/rest-nvim/rest.nvim/commit/2d970d01716ecd03f3f35340f6edbd0b40b878bf))
* quotes ([761bd07](https://github.com/rest-nvim/rest.nvim/commit/761bd0747613f680021167a31eba08600a06bbf5))
* readme table layout ([7184d14](https://github.com/rest-nvim/rest.nvim/commit/7184d14f8176d412b26d32da8e9ca6c813d9711c))
* **README:** set proper repository for license badge ([de5cb9e](https://github.com/rest-nvim/rest.nvim/commit/de5cb9e76f278e002a3a7f1818bdb74d162b9d69))
* **README:** use a consistent coding style in packer example ([36351d8](https://github.com/rest-nvim/rest.nvim/commit/36351d887b91a6486477bb6692a0c24e32d3b43e))
* remove stylua edits ([0d22f4a](https://github.com/rest-nvim/rest.nvim/commit/0d22f4a22b17a2dde63ecc8d5541e101e739511e))
* remove unnecessary edits ([042d6d2](https://github.com/rest-nvim/rest.nvim/commit/042d6d25fe81ea83fe1e1002a844e06025d464b5))
* Removed forgotten print ([e1482ea](https://github.com/rest-nvim/rest.nvim/commit/e1482ea4333a019ec8ef6cf43f406d52e9782800))
* result_split_horizontal config getter ([948cf14](https://github.com/rest-nvim/rest.nvim/commit/948cf14cad1e8b01f50d72b7859df1ae6f35b290))
* tidy adding meta tags ([8b7d9df](https://github.com/rest-nvim/rest.nvim/commit/8b7d9df9fbf71efd074fcb21916c70fff44d9af2))
* typo in lua docstring ([aa63d33](https://github.com/rest-nvim/rest.nvim/commit/aa63d336723378c1f95dbfba029f387b9ee46459))
* undefined api ([4b1ae8a](https://github.com/rest-nvim/rest.nvim/commit/4b1ae8abfefbbc66c783c343d3d5b13265deb3ce))
* use config.get to read skip_ssl_verification setting ([4b8608e](https://github.com/rest-nvim/rest.nvim/commit/4b8608e6633ab1c555b9afd6c1724ca7f2ebcde5))
* yank curl command which includes double quotes ([1d76b3a](https://github.com/rest-nvim/rest.nvim/commit/1d76b3ac9d4f9d04026f24851828040809cd48d5))


### Reverts

* removed error logging from curl ([877291e](https://github.com/rest-nvim/rest.nvim/commit/877291e3996964ba198d7b20ebbd8222b9f262b8))
* temporarily revert stylua changes ([91795ef](https://github.com/rest-nvim/rest.nvim/commit/91795ef796455eb4c237880a5969143434495d3f))
