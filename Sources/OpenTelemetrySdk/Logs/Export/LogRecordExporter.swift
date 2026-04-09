/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public protocol LogRecordExporter {
  func export(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval?) -> ExportResult

  /// Shutdown the log exporter
  ///
  func shutdown(explicitTimeout: TimeInterval?)

  /// Processes all the log records that have not yet been processed
  ///
  func forceFlush(explicitTimeout: TimeInterval?) -> ExportResult
}

public extension LogRecordExporter {
  func export(logRecords: [ReadableLogRecord]) -> ExportResult {
    return export(logRecords: logRecords, explicitTimeout: nil)
  }

  func shutdown() {
    shutdown(explicitTimeout: nil)
  }

  func forceFlush() -> ExportResult {
    return forceFlush(explicitTimeout: nil)
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension LogRecordExporter {
  func exportAsync(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval?) async -> ExportResult {
    return export(logRecords: logRecords, explicitTimeout: explicitTimeout)
  }

  func shutdownAsync(explicitTimeout: TimeInterval?) async {
    shutdown(explicitTimeout: explicitTimeout)
  }

  func forceFlushAsync(explicitTimeout: TimeInterval?) async -> ExportResult {
    return forceFlush(explicitTimeout: explicitTimeout)
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
