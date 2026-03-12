/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

/// An async-await capable log record exporter that refines `LogRecordExporter`.
///
/// Existing exporters continue to work unchanged. New or existing exporters can
/// opt in to truly non-blocking exports by conforming to this protocol and
/// overriding the async methods.
///
/// Default implementations bridge to the synchronous `LogRecordExporter` methods
/// so that adopters only need to override the methods they want to make async.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol AsyncLogRecordExporter: LogRecordExporter, Sendable {
  /// Called to export log records asynchronously.
  /// - Parameter logRecords: the list of log records to be exported.
  /// - Parameter explicitTimeout: optional timeout for the export operation.
  func exportAsync(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval?) async -> ExportResult

  /// Called when the exporter is shut down, asynchronously.
  func shutdownAsync(explicitTimeout: TimeInterval?) async

  /// Processes all the log records that have not yet been processed, asynchronously.
  func forceFlushAsync(explicitTimeout: TimeInterval?) async -> ExportResult
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension AsyncLogRecordExporter {
  func exportAsync(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval?) async -> ExportResult {
    return (self as LogRecordExporter).export(logRecords: logRecords, explicitTimeout: explicitTimeout)
  }

  func shutdownAsync(explicitTimeout: TimeInterval?) async {
    (self as LogRecordExporter).shutdown(explicitTimeout: explicitTimeout)
  }

  func forceFlushAsync(explicitTimeout: TimeInterval?) async -> ExportResult {
    return (self as LogRecordExporter).forceFlush(explicitTimeout: explicitTimeout)
  }

  func exportAsync(logRecords: [ReadableLogRecord]) async -> ExportResult {
    return await exportAsync(logRecords: logRecords, explicitTimeout: nil)
  }

  func shutdownAsync() async {
    await shutdownAsync(explicitTimeout: nil)
  }

  func forceFlushAsync() async -> ExportResult {
    return await forceFlushAsync(explicitTimeout: nil)
  }
}
