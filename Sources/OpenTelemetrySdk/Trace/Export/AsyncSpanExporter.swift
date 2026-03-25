/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

/// An async-await capable span exporter that refines `SpanExporter`.
///
/// Existing exporters continue to work unchanged. New or existing exporters can
/// opt in to truly non-blocking exports by conforming to this protocol and
/// overriding the async methods.
///
/// Default implementations bridge to the synchronous `SpanExporter` methods so
/// that adopters only need to override the methods they want to make async.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol AsyncSpanExporter: SpanExporter, Sendable {
  /// Called to export sampled Spans asynchronously.
  /// - Parameter spans: the list of sampled Spans to be exported.
  /// - Parameter explicitTimeout: optional timeout for the export operation.
  @discardableResult func exportAsync(spans: [SpanData], explicitTimeout: TimeInterval?) async -> SpanExporterResultCode

  /// Exports the collection of sampled Spans that have not yet been exported, asynchronously.
  func flushAsync(explicitTimeout: TimeInterval?) async -> SpanExporterResultCode

  /// Called when the TracerSdkFactory is shut down, asynchronously.
  func shutdownAsync(explicitTimeout: TimeInterval?) async
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension AsyncSpanExporter {
  @discardableResult func exportAsync(spans: [SpanData], explicitTimeout: TimeInterval?) async -> SpanExporterResultCode {
    return (self as SpanExporter).export(spans: spans, explicitTimeout: explicitTimeout)
  }

  func flushAsync(explicitTimeout: TimeInterval?) async -> SpanExporterResultCode {
    return (self as SpanExporter).flush(explicitTimeout: explicitTimeout)
  }

  func shutdownAsync(explicitTimeout: TimeInterval?) async {
    (self as SpanExporter).shutdown(explicitTimeout: explicitTimeout)
  }

  @discardableResult func exportAsync(spans: [SpanData]) async -> SpanExporterResultCode {
    return await exportAsync(spans: spans, explicitTimeout: nil)
  }

  func flushAsync() async -> SpanExporterResultCode {
    return await flushAsync(explicitTimeout: nil)
  }

  func shutdownAsync() async {
    await shutdownAsync(explicitTimeout: nil)
  }
}
