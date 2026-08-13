/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public protocol LogRecordExporter: Sendable {
  func export(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval?) -> ExportResult

  /// Shutdown the log exporter
  ///
  func shutdown(explicitTimeout: TimeInterval?)

  /// Processes all the log records that have not yet been processed
  ///
  func forceFlush(explicitTimeout: TimeInterval?) -> ExportResult

  func export(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval?) async -> ExportResult

  func shutdown(explicitTimeout: TimeInterval?) async

  func forceFlush(explicitTimeout: TimeInterval?) async -> ExportResult
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

public extension LogRecordExporter {
  func export(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval?) async -> ExportResult {
    assertionFailure("async export(logRecords:explicitTimeout:) must be implemented by \(type(of: self))")
    return .failure
  }

  func shutdown(explicitTimeout: TimeInterval?) async {
    assertionFailure("async shutdown(explicitTimeout:) must be implemented by \(type(of: self))")
  }

  func forceFlush(explicitTimeout: TimeInterval?) async -> ExportResult {
    assertionFailure("async forceFlush(explicitTimeout:) must be implemented by \(type(of: self))")
    return .failure
  }

  func export(logRecords: [ReadableLogRecord]) async -> ExportResult {
    return await export(logRecords: logRecords, explicitTimeout: nil)
  }

  func shutdown() async {
    await shutdown(explicitTimeout: nil)
  }

  func forceFlush() async -> ExportResult {
    return await forceFlush(explicitTimeout: nil)
  }
}
