/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

/// An async-await capable metric exporter that refines `MetricExporter`.
///
/// Existing exporters continue to work unchanged. New or existing exporters can
/// opt in to truly non-blocking exports by conforming to this protocol and
/// overriding the async methods.
///
/// Default implementations bridge to the synchronous `MetricExporter` methods
/// so that adopters only need to override the methods they want to make async.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol AsyncMetricExporter: MetricExporter, Sendable {
  /// Called to export metrics asynchronously.
  /// - Parameter metrics: the list of metric data to be exported.
  func exportAsync(metrics: [MetricData]) async -> ExportResult

  /// Flushes any pending metric data, asynchronously.
  func flushAsync() async -> ExportResult

  /// Shuts down the exporter, asynchronously.
  func shutdownAsync() async -> ExportResult
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension AsyncMetricExporter {
  func exportAsync(metrics: [MetricData]) async -> ExportResult {
    return (self as MetricExporter).export(metrics: metrics)
  }

  func flushAsync() async -> ExportResult {
    return (self as MetricExporter).flush()
  }

  func shutdownAsync() async -> ExportResult {
    return (self as MetricExporter).shutdown()
  }
}
