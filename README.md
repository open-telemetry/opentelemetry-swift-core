# <img src="https://opentelemetry.io/img/logos/opentelemetry-logo-nav.png" alt="OpenTelemetry Icon" width="45" height=""> opentelemetry-swift

[![CI](https://github.com/open-telemetry/opentelemetry-swift/actions/workflows/BuildAndTest.yml/badge.svg)](https://github.com/open-telemetry/opentelemetry-swift/actions/workflows/BuildAndTest.yml?query=branch%3Amain+)
[![codecov](https://codecov.io/gh/open-telemetry/opentelemetry-swift/branch/master/graph/badge.svg)](https://codecov.io/gh/open-telemetry/opentelemetry-swift)

## About

The repository contains the Swift [OpenTelemetry](https://opentelemetry.io/) client

## Getting Started

This package includes several libraries. The `OpenTelemetryApi` library includes protocols and no-op implementations that comprise the OpenTelemetry API following the [specification](https://github.com/open-telemetry/opentelemetry-specification). The `OpenTelemetrySdk` library is the reference implementation of the API.

Libraries that produce telemetry data should only depend on `OpenTelemetryApi`, and defer the choice of the SDK to the application developer. Applications may depend on `OpenTelemetrySdk` or another package that implements the API.

### Adding the dependency

opentelemetry-swift is designed for Swift 5. To depend on the  opentelemetry-swift package, you need to declare your dependency in your `Package.swift`:

```swift
.package(url: "https://github.com/open-telemetry/opentelemetry-swift", from: "1.0.0"),
```

and to your application/library target, add `OpenTelemetryApi` or  `OpenTelemetrySdk`to your `dependencies`, e.g. like this:

```swift
.target(name: "ExampleTelemetryProducerApp", dependencies: ["OpenTelemetryApi"]),
```

or

```swift
.target(name: "ExampleApp", dependencies: ["OpenTelemetrySdk"]),
```

### Cocoapods

As of version 1.11.0, OpenTelemetry-Swift support cocoapods. 
Two pods are provided: 

- `OpenTelemetry-Swift-Api`

- `OpenTelemetry-Swift-Sdk`

`OpenTelemetry-Swift-Api` is a dependency of `OpenTelemetry-Swift-Sdk`. 

Most users will want to add the following to their pod file:

`pod 'OpenTelemetry-Swift-Sdk'`

This will add both the API and SDK. If you're only interesting in Adding the API add the following: 

`pod 'OpenTelemetry-Swift-Api'`

## Documentation

Official documentation for the library can be found in the official opentelemetry [documentation  page](https://opentelemetry.io/docs/instrumentation/swift/), including:

* Documentation about installation and [manual instrumentation](https://opentelemetry.io/docs/instrumentation/swift/manual/)

* [Libraries](https://opentelemetry.io/docs/instrumentation/swift/libraries/) that provide automatic instrumentation

## Current status

### API and SDK

Tracing and Baggage are considered stable

Logs are considered stable. 

Metrics is considered stable.

## Contributing
We'd love your help! Use labels [![help wanted](https://img.shields.io/github/issues-search/open-telemetry/opentelemetry-swift?query=is%3Aissue%20is%3Aopen%20label%3A%22help%20wanted%22&label=help%20wanted&color=rgb(0%2C%20134%2C%20114)&logo=opentelemetry)](https://github.com/open-telemetry/opentelemetry-swift/issues?q=state%3Aopen%20label%3A%22help%20wanted%22) and [![good first issue](https://img.shields.io/github/issues-search/open-telemetry/opentelemetry-swift?query=is%3Aissue%20is%3Aopen%20label%3A%22good%20first%20issue%22&label=good%20first%20issue&color=rgb(112%2C%2087%2C%20255)&logo=opentelemetry)](https://github.com/open-telemetry/opentelemetry-swift/issues?q=state%3Aopen%20label%3A%22good%20first%20issue%22) 
 to get started with the project. 
For an overview of how to contribute, see the contributing guide in [CONTRIBUTING.md](CONTRIBUTING.md).

We have a weekly SIG meeting! See the [community page](https://github.com/open-telemetry/community#swift-sdk) for meeting details and notes.

We are also available in the [#otel-swift](https://cloud-native.slack.com/archives/C01NCHR19SB) channel in the [CNCF slack](https://slack.cncf.io/). Please join us there for OTel Swift discussions.

### Release process
This project uses github releases to track release versions. Cocoapods are also delpoyed using the automated release process. Github actions are used to streamline the release project and generate tags and release notes with minimal intervention. 
The Release process has several phases:
1. Preperation
2. `Framework Release` Github action
3. On Release PR Merge
4. Tag & Release notes

#### Preperation
When it is deemed appropriate by the project maintainers to create a release a few peperations should be accounted for:
* Are all relevant PRs merged into `main`?
* What version number is appropriate? e.g.: is this a hotfix, minor, or major release?
* Are all dependencies in the `Package.swift` using appropriate version numbers? (no branches in dependency defintion)

This isn't a complete list, so use your best instincts. 


#### `Framework Release` Github action

Once preperations are complete, run the [`Framework Release` Github action](https://github.com/open-telemetry/opentelemetry-swift-core/blob/main/.github/workflows/Create-Release-PR.yml).  This job takes the version you selected and creates a PR updating all the necessary version locations, such as the sdk.telemetry.version, docs, and Cocoapod podspecs. 
This release PR needs to be manually merged and reviewed. 

An [additional job](https://github.com/open-telemetry/opentelemetry-swift-core/blob/main/.github/workflows/PR-Release-Warning.yml) will also be run in the background adding a WARNING to the release PR indicating subsequent jobs will automatically be triggered after merge. This job detects the Release PR based of the branch name, and will show up if you use that naming scheme in any PR, so watchout for it. 

**Note**: The `Framework Release` job should always be run on the `main` branch.

#### On Release PR merged
Once the release PR is merged an automated job is kicked off: [`Tag and Release`](https://github.com/open-telemetry/opentelemetry-swift-core/blob/main/.github/workflows/Tag-And-Release.yml)

This job will run once the release PR is merged, based off the format of the PR branch name. It will auto generate a Github release, as well as push all Cocoapod specs to the Cocoapods Trunk. 


#### Tag & Release notes 
The release will be set as `pre-release` which allows maintainers to edit the auto-generated release notes into the appropriate format and provides a final go/no-go allowance for the release. 
The notes should be formatted into categories based on area of concern : e.g.: `Trace`, `Metrics`, `Instrumentation`.

Look to older releases for inspriation. 

### Maintainers ([@open-telemetry/swift-core-maintainers](https://github.com/orgs/open-telemetry/teams/swift-core-maintainers))

- [Ariel Demarco](https://github.com/arieldemarco), Embrace
- [Bryce Buchanan](https://github.com/bryce-b), Elastic
- [Ignacio Bonafonte](https://github.com/nachobonafonte), Independent

For more information about the maintainer role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#maintainer).

### Approvers ([@open-telemetry/swift-core-approvers](https://github.com/orgs/open-telemetry/teams/swift-core-approvers))

- [Austin Emmons](https://github.com/atreat), Embrace
- [Vinod Vydier](https://github.com/vvydier), Independent

For more information about the approver role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#approver).

### Triager ([@open-telemetry/swift-core-triagers](https://github.com/orgs/open-telemetry/teams/swift-core-triagers))

- [Alolita Sharma](https://github.com/alolita), Apple

For more information about the triager role, see the [community repository](https://github.com/open-telemetry/community/blob/main/community-membership.md#triager).
