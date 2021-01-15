# AEPCore

<!--
on [![Cocoapods](https://img.shields.io/cocoapods/v/AEPCore.svg?color=orange&label=AEPCore&logo=apple&logoColor=white)](https://cocoapods.org/pods/AEPCore)
-->
[![SPM](https://img.shields.io/badge/SPM-Supported-orange.svg?logo=apple&logoColor=white)](https://swift.org/package-manager/)
[![CircleCI](https://img.shields.io/circleci/project/github/adobe/aepsdk-core-ios/master.svg?logo=circleci)](https://circleci.com/gh/adobe/workflows/aepsdk-core-ios)
[![Code Coverage](https://img.shields.io/codecov/c/github/adobe/aepsdk-core-ios/main.svg?logo=codecov)](https://codecov.io/gh/adobe/aepsdk-core-ios/branch/main)

## About this project

The Mobile Core represents the core Adobe Experience Platform SDK that is required for every app implementation. The core contains a common set of functionality and frameworks, such as  Experience Cloud Identity services, data event hub, Rules Engine, reusable networking, disk access routines, and so on, which are required by all Adobe and third-party extensions.

## Requirements
- Xcode 11.0 (or newer)
- Swift 5.1 (or newer)

## Installation
These are currently the supported installation options:

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)
```ruby
# Podfile
use_frameworks!

# for app development, include all the following pods
target 'YOUR_TARGET_NAME' do
    pod 'AEPCore'
    pod 'AEPLifecycle'
    pod 'AEPIdentity'
    pod 'AEPSignal'
end

# for extension development, include AEPCore and its dependencies
target 'YOUR_TARGET_NAME' do
    pod 'AEPCore'
end
```

Replace `YOUR_TARGET_NAME` and then, in the `Podfile` directory, type:

```bash
$ pod install
```

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

To add the AEPCore Package to your application, from the Xcode menu select:

`File > Swift Packages > Add Package Dependency...`

Enter the URL for the AEPCore package repository: `https://github.com/adobe/aepsdk-core-ios.git`.

When prompted, make sure you change the branch to `main`. (Once the repo is public, we will reference specific tags/versions instead of a branch)

There are three options for selecting your dependencies as identified by the *suffix* of the library name:

- "Dynamic" - the library will be linked dynamically
- "Static" - the library will be linked statically
- *(none)* - (default) SPM will determine whether the library will be linked dynamically or statically

Alternatively, if your project has a `Package.swift` file, you can add AEPCore directly to your dependencies:

```
dependencies: [
    .package(url: "https://github.com/adobe/aepsdk-core-ios.git", .branch("main"))
]
```

### Project Reference

Include `AEPCore.xcodeproj` in the targeted Xcode project and link all necessary libraries to your app target.

### Binaries

Run `make archive` from the root directory to generate `.xcframeworks` for each module under the `build` folder. Drag and drop all `.xcframeworks` to your app target in Xcode.

## Documentation

Additional documentation for usage and SDK architecture can be found under the [Documentation](Documentation/README.md) directory.

## Related Projects

| Project      | Description |
| ------------ | ----------- |
| [AEPEdge Extension](https://github.com/adobe/aepsdk-edge-ios) | Provides support to the Experience Platform Edge for the AEP SDK. |
| [AEPRulesEngine](https://github.com/adobe/aepsdk-rulesengine-ios) | Implementation of the Rules Engine used by the AEP SDK. |
| [AEP SDK Sample App for iOS](https://github.com/adobe/aepsdk-sample-app-ios) | Contains iOS sample apps for the AEP SDK. Apps are provided for both Objective-C and Swift implementations. |
| [AEP SDK Sample Extension for iOS](https://github.com/adobe/aepsdk-sample-extension-ios) | Contains a sample implementation of an iOS extension for the AEP SDK. Example implementations are provided for both Objective-C and Swift.
| [AEP SDK Compatibility for iOS](https://github.com/adobe/aepsdk-compatibility-ios) | Contains code that bridges `ACPCore` and 3rd party extension implementations into the AEP SDK runtime. |

## Contributing

Contributions are welcomed! Read the [Contributing Guide](./.github/CONTRIBUTING.md) for more information.

## Licensing

This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.
