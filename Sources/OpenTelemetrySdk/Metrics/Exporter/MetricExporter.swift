//
// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@available(*, deprecated, renamed: "MetricExporter")
public typealias StableMetricExporter = MetricExporter

public protocol MetricExporter: AggregationTemporalitySelectorProtocol, DefaultAggregationSelector {
  func export(metrics: [MetricData]) -> ExportResult
  func flush() -> ExportResult
  func shutdown() -> ExportResult

  /// Async variant of `export(metrics:)`.
  @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
  func exportAsync(metrics: [MetricData]) async -> ExportResult

  /// Async variant of `flush()`.
  @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
  func flushAsync() async -> ExportResult

  /// Async variant of `shutdown()`.
  @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
  func shutdownAsync() async -> ExportResult
}

public extension MetricExporter {
  func getDefaultAggregation(for instrument: InstrumentType) -> Aggregation {
    return Aggregations.defaultAggregation()
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension MetricExporter {
  func exportAsync(metrics: [MetricData]) async -> ExportResult {
    assertionFailure("exportAsync(metrics:) must be implemented by \(type(of: self))")
    return .failure
  }

  func flushAsync() async -> ExportResult {
    assertionFailure("flushAsync() must be implemented by \(type(of: self))")
    return .failure
  }

  func shutdownAsync() async -> ExportResult {
    assertionFailure("shutdownAsync() must be implemented by \(type(of: self))")
    return .failure
  }
}
