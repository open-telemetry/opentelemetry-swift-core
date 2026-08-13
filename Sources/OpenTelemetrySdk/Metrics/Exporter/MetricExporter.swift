//
// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@available(*, deprecated, renamed: "MetricExporter")
public typealias StableMetricExporter = MetricExporter

public protocol MetricExporter: AggregationTemporalitySelectorProtocol, DefaultAggregationSelector, Sendable {
  func export(metrics: [MetricData]) -> ExportResult
  func flush() -> ExportResult
  func shutdown() -> ExportResult

  func export(metrics: [MetricData]) async -> ExportResult

  func flush() async -> ExportResult

  func shutdown() async -> ExportResult
}

public extension MetricExporter {
  func getDefaultAggregation(for instrument: InstrumentType) -> Aggregation {
    return Aggregations.defaultAggregation()
  }
}

public extension MetricExporter {
  func export(metrics: [MetricData]) async -> ExportResult {
    assertionFailure("async export(metrics:) must be implemented by \(type(of: self))")
    return .failure
  }

  func flush() async -> ExportResult {
    assertionFailure("async flush() must be implemented by \(type(of: self))")
    return .failure
  }

  func shutdown() async -> ExportResult {
    assertionFailure("async shutdown() must be implemented by \(type(of: self))")
    return .failure
  }
}
