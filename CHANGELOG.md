# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## [2.8.0](https://github.com/lemonadesocial/lemonade-hardhat-environment/compare/v2.7.0...v2.8.0) (2022-07-27)


### Features

* replace rinkeby by goerli ([c09e7a5](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/c09e7a5a59dee246f6fbf230de4513a8558ae681))
* replace rpc environment variables by public endpoints ([367560b](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/367560bee4295d0e26fa59f6c746188af40666da))

## [2.7.0](https://github.com/lemonadesocial/lemonade-hardhat-environment/compare/v2.6.0...v2.7.0) (2022-07-20)


### Features

* add opal chain ([20acaab](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/20acaaba8abfd72172d3dba6be289a8f2659cadf))
* **LemonadeMarketplaceV1:** add native currency support ([aa9ddaa](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/aa9ddaa0d116b8b7fbbcb2116985256ab9d6115f))
* **LemonadeMarketplaceV1:** avoid ERC20 transfers with amount zero ([29f1333](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/29f1333360db19c0b1e2e0bbabc62b94beaeba05))
* **LemonadeMarketplaceV1:** move royalties to virtual functions for override ([92e70e8](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/92e70e80ac5d4f81c6cfbc932bd3f2bd50aba255))
* **LemonadeMarketplaceV1Unique:** add Unique variant of Lemonade marketplace contract ([a813fd0](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/a813fd02b0e9bc46af1565300dc933449adb2516))
* **LemonadeMarketplaceV1:** use ERC721 transferFrom instead of safeTransferFrom ([a7fc221](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/a7fc221e954049565d3718cccdda7783b6064b7a))
* **LemonadePoapV1Unique:** add Unique variant of Lemonade POAP contract ([b4f85ad](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/b4f85ad1a629dce9b92ecc2b4bc4e4d182fcca8e))
* **LemonadeUniqueCollectionV1:** add Lemonade Unique collection contract ([f675e02](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/f675e02be5cb2fa5bb0a302ca5b15f810f435ce6))
* **LemonadeUniqueCollectionV1:** make collection public ([40c8637](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/40c8637ec9e434a21d4e65e29962c0cc3871984b))
* **LemonadeUniqueCollectionV1:** share mintable interface with ERC721LemonadeV1 ([01fa265](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/01fa2655c6ec3951a013c22cdffef44f2cfc2226))

## [2.6.0](https://github.com/lemonadesocial/lemonade-hardhat-environment/compare/v2.5.0...v2.6.0) (2022-06-29)


### Features

* add bnb testnet and bnb access registry deployments ([23ef086](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/23ef086c3126da4e241b5e3f9deb51d527c320a1))
* add moonbase and moonbeam access registry deployments ([5c0a434](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/5c0a43453cea4ae817718dde93899dc612270f18))
* **LemonadeMarketplace:** make fee variables private ([dcad3c6](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/dcad3c61a2c58c99b580fcd02c09ab4a18651929))
* **LemonadeMarketplace:** remove pausible ([be53fd2](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/be53fd228fd172c38b0d4e3bf4b3a1a45e8aede5))
* **LemonadeMarketplace:** remove set trusted forwarder ([9a3d2d9](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/9a3d2d91d13c2f6a9d4492d187da6b46cca67852))
* **LemonadePoap:** add external access registry ([cc1a981](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/cc1a9819045354f6685f2b30b99418399c953daa))
* **LemonadePoap:** mark variables as immutable ([aecd4b8](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/aecd4b81255e99e1ca53f1873f262494adaa8fc0))
* upgrade mumbai and polygon deployments ([fcea82f](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/fcea82f38b6838a68c8ded3c7e05bdef74b649dc))

## [2.5.0](https://github.com/lemonadesocial/lemonade-hardhat-environment/compare/v2.4.0...v2.5.0) (2022-06-24)


### Features

* add aurora testnet, aurora, bnb, and bnb testnet chains ([10c854b](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/10c854b2544c1e4dce585a445ea0a28c2a1a3d74))
* update moonbase trusted forwarder ([329c238](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/329c2384483b14fe3362511095cfeab16c11dd00))

## [2.4.0](https://github.com/lemonadesocial/lemonade-hardhat-environment/compare/v2.3.0...v2.4.0) (2022-06-03)


### Features

* add moonbase and moonbeam deploys ([9dee746](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/9dee746d11ad92c8ef9541f4621b012f0731e5ea))
* **LemonadePoapV1:** add trusted claimer ([dd5762f](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/dd5762f3ff584dc1822098673630989165e695e4))
* **LemonadePoapV1:** make has claimed plural ([78f486c](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/78f486c2a3369cdb22aa759e05f39dfa62a75d9f))
* **LemonadePoapV1:** optimize gas ([6ef7487](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/6ef7487d238372ed6f611a8048507fdd02157332))
* **LemonadePoapV1:** update supply tracking ([730af50](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/730af50f4e685f81e9307f7817540a09f5d261cb))

## [2.3.0](https://github.com/lemonadesocial/lemonade-hardhat-environment/compare/v2.2.0...v2.3.0) (2022-05-20)


### Features

* add ethereum deploys ([41e0791](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/41e07913e5800242655026bbc8900a39bec61a30))
* add rinkeby deploys ([9069dd6](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/9069dd6eb5df5c96fe9c0102b7741bd06816ec7a))
* **ERC721ClaimableV2:** make contract ownable ([e50dd5f](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/e50dd5f5d467d2df9df9feb4f28388f6716d1afe))
* **ERC721CollectionV1:** add minimal ERC721 collection contract ([4c89497](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/4c89497f5cd79b3f9a916dd4c155ee03a7ec95d7))
* **LemonadePoapV1:** add Lemonade POAP contract ([3430070](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/34300708496af4ad8464949c6c51fee7f92eb988))
* **misc:** allow using private key directly instead of mnemonic ([64c5345](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/64c534519d348ea9b57ab3726d380a9789995093))
* **misc:** enable optimizer ([c6282c0](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/c6282c08bd6158d8dee46b41586cb6dfaf3623c0))
* split LemonadeMarketplace and ERC721Lemonade contracts ([37f0910](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/37f0910f452d4a25ffe730d25a24f0bc731f8788))

## [2.2.0](https://github.com/lemonadesocial/lemonade-hardhat-environment/compare/v2.1.0...v2.2.0) (2022-02-23)


### Features

* **ERC721ClaimableV2:** add claimable contract ([692a082](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/692a082e0b074383357fdaf5d22dada14e88a847))
* **ERC721ClaimableV2:** add royalties and opensea support ([af53ed0](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/af53ed03bc3bf56661d0ecaa1daecb0fdb997c92))

## [2.1.0](https://github.com/lemonadesocial/lemonade-hardhat-environment/compare/v2.0.0...v2.1.0) (2022-01-19)


### Features

* **ERC721Claimable:** add meta transaction support ([527b6a6](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/527b6a612f1766cc87da73f25fe94e0496f1f2b5))
* **ERC721Lemonade:** add meta transaction support ([836c3c6](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/836c3c643c870eef7eafd0fdd7f265bef255d903))
* **ERC721Lemonade:** remove withdraw batch limit ([96dff46](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/96dff46db908eafae0a1bd3a8f2feaa0b1052109))
* **forwarder:** fix forwarder contracts build ([c800715](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/c8007153b04aafd9097d6e537a9bbedc99bae4f0))
* **forwarder:** import forwarder contracts ([976917b](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/976917bd4177deae3492108885ca86a4db2118fd))
* **LemonadeMarketplace:** add meta transaction support ([0823262](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/082326285b040514a311e4f963f58a60a345683d))
* **RelayRecipient:** add relay recipient contract ([16e9ed7](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/16e9ed75fce0d7f3dad6f167818b0b4e9e3fafa6))
* update deployments ([cd72d33](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/cd72d33ccab6ea34024a6645bf5ff6d8daec7857))

## [2.0.0](https://github.com/lemonadesocial/lemonade-hardhat-environment/compare/v1.3.0...v2.0.0) (2021-12-16)


### ⚠ BREAKING CHANGES

* **LemonadeMarketplace:** update fee precision
* **LemonadeMarketplace:** add extended royalties support
* **ERC721LemonadeParent:** add extended royalties support
* **ERC721Lemonade:** add extended royalties support

### Features

* **ERC721Claimable:** add claimable token contract ([eeba504](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/eeba504a799ed57e77774bc1613d31d0d433ad84))
* **ERC721Claimable:** reserve first token for creator ([754ec86](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/754ec86bcae6cc8733ccbdbe54757f546dbc1e5f))
* **ERC721Lemonade:** add extended royalties support ([37ca7c1](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/37ca7c14aad97b9b0f382f5ef3d569808e6681ee))
* **ERC721Lemonade:** add state transfer support to batch withdraw ([853c7ed](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/853c7edddf0d35205efbf547eb54fc217f91f61f))
* **ERC721LemonadeParent:** add extended royalties support ([2a7b5e2](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/2a7b5e29c63c3d527f03628bd06ca099d100c28b))
* **LemonadeMarketplace:** add extended royalties support ([8945758](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/8945758b4a65a999b0a423646f6eee205c6eb098))
* **LemonadeMarketplace:** increase max auction duration to 30 days ([e502f03](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/e502f034791c4e5ad136c1d3f3b6b54a6d8ccd04))
* **LemonadeMarketplace:** update fee precision ([a8df88b](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/a8df88b9beebff9b9c7d4d33b4d68f0f3380c5cc))
* **royalties:** add contract with erc2981 and rarible royalties v2 support ([9745a09](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/9745a0977c9c494630b30847e9a9ecbb51397f7e))
* **royalties:** fix rarible contracts build ([a4c2fb7](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/a4c2fb75aa5b676963d59a2f7cd663643ae09fa5))
* **royalties:** import rarible contracts ([6baf1db](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/6baf1db7b42929917fe12f8dd5684d273e45582f))
* update deployments ([34582fb](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/34582fb67b8f25329580b9ff55ecdcc7f3b1278f))

## [1.3.0](https://github.com/lemonadesocial/lemonade-hardhat-environment/compare/v1.2.0...v1.3.0) (2021-11-18)


### Features

* **ERC721Lemonade:** add parent chain mapping support ([9c0d1d7](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/9c0d1d7aa43f913bb657181144a95ec3adc74fb2))
* **ERC721LemonadeParent:** add parent chain erc721 contract ([26708f5](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/26708f52c164345e66da81ae7a0fa7140f491a29))
* **ERC721Lemonade:** update deployments ([facf7ac](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/facf7ac603eab7fb7b6ed36ac9172eb6ef43ff49))
* **ERC721Royalty:** add erc165 support ([c68c604](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/c68c604e51f67a3fa57b0f856203f1e81acc0a8a))

## [1.2.0](https://github.com/lemonadesocial/lemonade-hardhat-environment/compare/v1.1.1...v1.2.0) (2021-11-10)


### Features

* **LemonadeMarketplace:** add polygon deployment ([bf7a3ff](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/bf7a3ff3d2018ef18cb7ed4e845fb7d1699516e2))

### [1.1.1](https://github.com/lemonadesocial/lemonade-hardhat-environment/compare/v1.1.0...v1.1.1) (2021-11-04)


### Bug Fixes

* **LemonadeMarketplace:** fix incorrect maximum auction order duration ([6995975](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/6995975a312d7812d0052e01ba733df572a02472))

## [1.1.0](https://github.com/lemonadesocial/lemonade-hardhat-environment/compare/v1.0.0...v1.1.0) (2021-11-01)


### Features

* **LemonadeMarketplace:** add fee view ([7c33bd8](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/7c33bd86a046948706d4457138cc9c0ba24a1299))
* **LemonadeMarketplace:** add mumbai deployment ([3f5e0af](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/3f5e0af00c1377d6493101f7fdee8a81eb79201d))
* **LemonadeMarketplace:** add support for direct orders with open from and to ([5c406b3](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/5c406b3962c0d13d1bda53e95f62505848a8397d))
* **LemonadeMarketplace:** allow final bidder to fill auction order ([b461760](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/b46176095669130cd817bac967d9d7849dfb4acd))
* **LemonadeMarketplace:** limit auction order duration to max 7 days ([364124c](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/364124cab2b6950f6b5a74fd7916ff7125dc8e54))
* **LemonadeMarketplace:** set fee percentage to 2% ([835083f](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/835083ff4c809d940681381119ad04e1f867df10))
* **LemonadeMarketplace:** validate open from and to when creating order ([36b42f5](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/36b42f575338d30878e9b792749a7c03a540d889))

## 1.0.0 (2021-11-01)


### Features

* **ERC721Lemonade:** add deploy script ([25b7a70](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/25b7a70b7680406d33f3d8949188b6c55f9be74c))
* **ERC721Lemonade:** add deployments for polygon and mumbai ([3f73b16](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/3f73b16ff0609a26e2c618ff0aeebb61876fce4f))
* **ERC721Lemonade:** import contracts ([9aa7f2c](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/9aa7f2cd5f81376c788a9eea11441ad6b6582f2f))
* **LemonadeMarketplace:** add deploy script ([7deaaf6](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/7deaaf604f1ead71bb6ebc3c3367e944822ebc14))
* **LemonadeMarketplace:** import contract ([135d5ab](https://github.com/lemonadesocial/lemonade-hardhat-environment/commit/135d5ab85a2166074a740a17a1f966faf9db5673))
