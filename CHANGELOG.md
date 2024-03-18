# Changelog

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
