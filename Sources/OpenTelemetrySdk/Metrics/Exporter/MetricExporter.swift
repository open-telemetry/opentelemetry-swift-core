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
}

public extension MetricExporter {
  func getDefaultAggregation(for instrument: InstrumentType) -> Aggregation {
    return Aggregations.defaultAggregation()
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension MetricExporter {
  func exportAsync(metrics: [MetricData]) async -> ExportResult {
    return export(metrics: metrics)
  }

  func flushAsync() async -> ExportResult {
    return flush()
  }

  func shutdownAsync() async -> ExportResult {
    return shutdown()
  }
}
