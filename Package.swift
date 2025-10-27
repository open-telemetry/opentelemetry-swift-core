// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let package = Package(
  name: "opentelemetry-swift-core",
  platforms: [
    .macOS(.v10_13),
    .iOS(.v12),
    .tvOS(.v12),
    .watchOS(.v4),
    .visionOS(.v1),
  ],
  products: [
    .library(name: "OpenTelemetryApi", targets: ["OpenTelemetryApi"]),
    .library(name: "OpenTelemetryConcurrency", targets: ["OpenTelemetryConcurrency"]),
    .library(name: "OpenTelemetrySdk", targets: ["OpenTelemetrySdk"]),
    .library(name: "StdoutExporter", targets: ["StdoutExporter"]),
    .executable(name: "ConcurrencyContext", targets: ["ConcurrencyContext"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-atomics.git", from: "1.3.0"),
  ],
  targets: [
    .target(
      name: "OpenTelemetryApi",
      dependencies: []
    ),
    .target(
      name: "OpenTelemetrySdk",
      dependencies: [
        "OpenTelemetryApi",
        .product(name: "Atomics", package: "swift-atomics", condition: .when(platforms: [.linux])),
      ]
    ),
    .target(
      name: "OpenTelemetryConcurrency",
      dependencies: ["OpenTelemetryApi"]
    ),
    .target(
      name: "StdoutExporter",
      dependencies: ["OpenTelemetrySdk"],
      path: "Sources/Exporters/Stdout"
    ),
    .target(
      name: "OpenTelemetryTestUtils",
      dependencies: ["OpenTelemetryApi", "OpenTelemetrySdk"]
    ),
    .testTarget(
      name: "OpenTelemetryApiTests",
      dependencies: ["OpenTelemetryApi", "OpenTelemetryTestUtils"],
      path: "Tests/OpenTelemetryApiTests"
    ),
    .testTarget(
      name: "OpenTelemetrySdkTests",
      dependencies: [
        "OpenTelemetrySdk",
        "OpenTelemetryConcurrency",
        "OpenTelemetryTestUtils",
      ],
      path: "Tests/OpenTelemetrySdkTests"
    ),
    .executableTarget(
      name: "ConcurrencyContext",
      dependencies: ["OpenTelemetrySdk", "OpenTelemetryConcurrency", "StdoutExporter"],
      path: "Examples/ConcurrencyContext"
    ),
  ]
)

if ProcessInfo.processInfo.environment["OTEL_ENABLE_SWIFTLINT"] != nil {
  package.dependencies.append(contentsOf: [
    .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.57.1")
  ])

  for target in package.targets {
    target.plugins = [
      .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
    ]
  }
}
