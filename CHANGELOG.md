# Change Log
All notable changes to this project will be documented in this file.
`PurchaseController` adheres to [Semantic Versioning](https://semver.org/).

#### 0.x Releases
- `0.4.x` Releases - [0.4.0](#040) | [0.4.1](#041) | [0.4.2](#042) | [0.4.3](#043) | [0.4.4](#044) | [0.4.5](#045)
- `0.3.x` Releases - [0.3.0](#030)
- `0.2.x` Releases - [0.2.0](#020) 
- `0.1.x` Releases - [0.1.0](#010) 

---

## [0.4.5](https://github.com/dashdevs/PurchaseController/releases/tag/0.4.5)
Released on 2019-06-25. 

#### Added
- Contributing rules file and change log to project.
    - Added by [Igor Kulik](https://github.com/igor-kulik) in pull request [`#2`](https://github.com/dashdevs/PurchaseController/pull/2). 
- Receipt conversion to JSON dictioanary and Base64-encoded string.
    - Added by [Igor Kulik](https://github.com/igor-kulik) in pull request [`#4`](https://github.com/dashdevs/PurchaseController/pull/4). 
- Local receipt validation.
    - Added by [Igor Kulik](https://github.com/igor-kulik) in commit [`c71abb5`](https://github.com/dashdevs/PurchaseController/commit/c71abb541c1226648c276f2e890396e8901da24c). 
- Methods for fetching all products.
    - Added by [Igor Kulik](https://github.com/igor-kulik) in commit [`fc3cfb9`](https://github.com/dashdevs/PurchaseController/commit/fc3cfb9befb89b867d9ecc97dacd466752100718). 

#### Updated
- Podspec file.
    - Updated by [Igor Kulik](https://github.com/igor-kulik) in commit [`faf1bcc`](https://github.com/dashdevs/PurchaseController/commit/faf1bcc1dc00292ab4a8fa82f55d7676e0a06aa3). 
- PurchaseError type.
    - Updated by [Igor Kulik](https://github.com/igor-kulik) in pull request [`#1`](https://github.com/dashdevs/PurchaseController/pull/1). 

## [0.4.4](https://github.com/dashdevs/PurchaseController/releases/tag/0.4.4)
Released on 2019-06-17. 

#### Added
- Completion methods for specific transaction.
    - Added by [Valeriy Jefimov](https://github.com/JefimovValeriy) in commit [`f0c29b4`](https://github.com/dashdevs/PurchaseController/commit/f0c29b416f96804b483cc7475c7fc705f164e731). 
- Deprecated method to fetch receipt of particular transaction.
    - Added by [Valeriy Jefimov](https://github.com/JefimovValeriy) in commit [`65d0499`](https://github.com/dashdevs/PurchaseController/commit/65d0499f4ec8953e6598554153d451ad8207480c). 
- `atomically` flag to `PurchaseController.purchase()` method.
    - Added by [Igor Kulik](https://github.com/igor-kulik) in commit [`2bcb7b5`](https://github.com/dashdevs/PurchaseController/commit/2bcb7b56e39ee1ed72335175eb5769c5ed6d0e07). 

#### Updated
- Podspec file.
    - Updated by [Igor Kulik](https://github.com/igor-kulik) in commit [`1328a8b`](https://github.com/dashdevs/PurchaseController/commit/1328a8bafcaf8c47cd3f3e1493010b72920f7e6e). 

## [0.4.3](https://github.com/dashdevs/PurchaseController/releases/tag/0.4.3)
Released on 2019-06-13. 

#### Updated
- Podspec file.
    - Updated by [Igor Kulik](https://github.com/igor-kulik) in commit [`6f04c4e`](https://github.com/dashdevs/PurchaseController/commit/6f04c4ef0b308a9a42fb579092a83a9ce55fda4d). 
- `PurchasePersistorImplementation.localProducts` to dictionary type.
    - Updated by [Igor Kulik](https://github.com/igor-kulik) in commit [`6eceb86`](https://github.com/dashdevs/PurchaseController/commit/6eceb86b2d4676645305ea35e44a99ff15eccc0b). 

## [0.4.2](https://github.com/dashdevs/PurchaseController/releases/tag/0.4.2)
Released on 2019-05-24. 

#### Updated
- Podspec file and example project.
    - Updated by [Vlad Arsenyuk](https://github.com/vladarsenyuk) in commit [`252fe55`](https://github.com/dashdevs/PurchaseController/commit/252fe55b24b62f3b0b31ad5e1b2e667b1a3a873c). 
- `PurchaseController` logic.
    - Updated by [Vlad Arsenyuk](https://github.com/vladarsenyuk) in commit [`5cd092e`](https://github.com/dashdevs/PurchaseController/commit/5cd092e94b6495cd82bc12508a1bd4618684f768). 

## [0.4.1](https://github.com/dashdevs/PurchaseController/releases/tag/0.4.1)
Released on 2019-05-23. 

#### Updated
- Podspec file.
    - Updated by [Vlad Arsenyuk](https://github.com/vladarsenyuk) in commit [`100fec4`](https://github.com/dashdevs/PurchaseController/commit/100fec42b7ddac9b342e62a2a7a256e1424d35e2). 

#### Fixed
- Receipt decoding issues.
    - Fixed by [Vlad Arsenyuk](https://github.com/vladarsenyuk) in commit [`498b7d8`](https://github.com/dashdevs/PurchaseController/commit/498b7d8baee2c6600d08902c74b3d07410505851). 

## [0.4.0](https://github.com/dashdevs/PurchaseController/releases/tag/0.4.0)
Released on 2019-05-21. 

#### Added
- Receipt refresh functionality.
    - Added by [Vlad Arsenyuk](https://github.com/vladarsenyuk) in commit [`b95d63d`](https://github.com/dashdevs/PurchaseController/commit/b95d63df21cb05f28b7e8305e7e0c686b44b67a6).
- Receipt data models.
    - Added by [Vlad Arsenyuk](https://github.com/vladarsenyuk) in commit [`d8483e6`](https://github.com/dashdevs/PurchaseController/tree/d8483e6f2ef26d03364c332649106f9b34d068c8).

#### Updated
- Purchase handling with new error code cases.
    - Updated by [Vlad Arsenyuk](https://github.com/vladarsenyuk) in commit [`cb7088f`](https://github.com/dashdevs/PurchaseController/commit/cb7088f14ee4813735c8165687e38179c61fca7b). 

## [0.3.0](https://github.com/dashdevs/PurchaseController/releases/tag/0.3.0)
Released on 2019-02-28. 

#### Added
- Todo file.
    - Added by [Kirill Ushkov](https://github.com/kirill-ushkov) in commit [`431e51c`](https://github.com/dashdevs/PurchaseController/commit/431e51cd2a56bb45b34dd4351c483d78bc3baeef).
- Code documentation.
    - Added by [Valeriy Jefimov](https://github.com/JefimovValeriy) in commit [`55b6f7a`](https://github.com/dashdevs/PurchaseController/commit/55b6f7a6f7aba55f2d7f0ea0da6973d1c62af203).

#### Updated
- Todo file.
    - Updated by [Kirill Ushkov](https://github.com/kirill-ushkov) in commit [`b5ee318`](https://github.com/dashdevs/PurchaseController/tree/b5ee31816c8434e24776a477215ac8c0b1626982). 
- Podspec file.
    - Updated by [Kirill Ushkov](https://github.com/kirill-ushkov) in commit [`431e51c`](https://github.com/dashdevs/PurchaseController/commit/431e51cd2a56bb45b34dd4351c483d78bc3baeef). 

## [0.2.0](https://github.com/dashdevs/PurchaseController/releases/tag/0.2.0)
Released on 2019-02-26. 

#### Updated
-  Removed generic name state.
    - Updated by [Vlad Arsenyuk](https://github.com/vladarsenyuk) in commit [`e581c5c`](https://github.com/dashdevs/PurchaseController/commit/e581c5c23d6162025148eb67ce41543bea19568f).
- Version in podspec file and authors in readme file.
    - Updated by [Vlad Arsenyuk](https://github.com/vladarsenyuk) in commit [`e6cb25c`](https://github.com/dashdevs/PurchaseController/commit/e6cb25c16e6a1b4a0e71f223c48581909159f253). 

## [0.1.0](https://github.com/dashdevs/PurchaseController/releases/tag/0.1.0)
Released on 2019-02-21. 

#### Added
- Swift version in podspec file.
    - Added by [Kirill Ushkov](https://github.com/kirill-ushkov) in commit  [`641bb3c`](https://github.com/dashdevs/PurchaseController/commit/641bb3c927321e2a983a944c596eeeeb0e268e82).
- Basic funtionality .
    - Added by [Kirill Ushkov](https://github.com/kirill-ushkov) in commit  [`29f80de`](https://github.com/dashdevs/PurchaseController/commit/29f80de5698a1f00784acdc664973c1cfbfe55fa).
