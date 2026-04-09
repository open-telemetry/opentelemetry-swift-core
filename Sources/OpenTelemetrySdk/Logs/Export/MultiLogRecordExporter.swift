//
// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `@unchecked Sendable` because Swift cannot statically verify Sendable for
/// non-final classes. Safety is guaranteed by the immutable (`let`) stored property —
/// no synchronization is needed for concurrent reads of immutable state.
public class MultiLogRecordExporter: LogRecordExporter, @unchecked Sendable {
  let logRecordExporters: [LogRecordExporter]

  public init(logRecordExporters: [LogRecordExporter]) {
    self.logRecordExporters = logRecordExporters
  }

  public func export(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval? = nil) -> ExportResult {
    var result = ExportResult.success
    logRecordExporters.forEach {
      result.mergeResultCode(newResultCode: $0.export(logRecords: logRecords, explicitTimeout: explicitTimeout))
    }
    return result
  }

  public func shutdown(explicitTimeout: TimeInterval? = nil) {
    logRecordExporters.forEach {
      $0.shutdown(explicitTimeout: explicitTimeout)
    }
  }

  public func forceFlush(explicitTimeout: TimeInterval? = nil) -> ExportResult {
    var result = ExportResult.success
    logRecordExporters.forEach {
      result.mergeResultCode(newResultCode: $0.forceFlush(explicitTimeout: explicitTimeout))
    }
    return result
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension MultiLogRecordExporter {
  public func exportAsync(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval? = nil) async -> ExportResult {
    var result = ExportResult.success
    for exporter in logRecordExporters {
      result.mergeResultCode(newResultCode: exporter.export(logRecords: logRecords, explicitTimeout: explicitTimeout))
    }
    return result
  }

  public func shutdownAsync(explicitTimeout: TimeInterval? = nil) async {
    for exporter in logRecordExporters {
      exporter.shutdown(explicitTimeout: explicitTimeout)
    }
  }

  public func forceFlushAsync(explicitTimeout: TimeInterval? = nil) async -> ExportResult {
    var result = ExportResult.success
    for exporter in logRecordExporters {
      result.mergeResultCode(newResultCode: exporter.forceFlush(explicitTimeout: explicitTimeout))
    }
    return result
  }
}
