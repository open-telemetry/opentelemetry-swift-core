/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

/// Implementation of the SpanExporter that simply forwards all received spans to a list of
/// SpanExporter.
/// Can be used to export to multiple backends using the same SpanProcessor like a SimpleSpanProcessor
/// or a BatchSpanProcessor.
/// `@unchecked Sendable` because Swift cannot statically verify Sendable for
/// non-final classes. Safety is guaranteed by the immutable (`let`) stored property —
/// no synchronization is needed for concurrent reads of immutable state.
public class MultiSpanExporter: SpanExporter, @unchecked Sendable {
  let spanExporters: [SpanExporter]

  public init(spanExporters: [SpanExporter]) {
    self.spanExporters = spanExporters
  }

  public func export(spans: [SpanData], explicitTimeout: TimeInterval? = nil) -> SpanExporterResultCode {
    var currentResultCode = SpanExporterResultCode.success
    for exporter in spanExporters {
      currentResultCode.mergeResultCode(newResultCode: exporter.export(spans: spans, explicitTimeout: explicitTimeout))
    }
    return currentResultCode
  }

  public func flush(explicitTimeout: TimeInterval? = nil) -> SpanExporterResultCode {
    var currentResultCode = SpanExporterResultCode.success
    for exporter in spanExporters {
      currentResultCode.mergeResultCode(newResultCode: exporter.flush(explicitTimeout: explicitTimeout))
    }
    return currentResultCode
  }

  public func shutdown(explicitTimeout: TimeInterval? = nil) {
    for exporter in spanExporters {
      exporter.shutdown(explicitTimeout: explicitTimeout)
    }
  }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension MultiSpanExporter {
  public func exportAsync(spans: [SpanData], explicitTimeout: TimeInterval? = nil) async -> SpanExporterResultCode {
    await withTaskGroup(of: SpanExporterResultCode.self, returning: SpanExporterResultCode.self) { group in
      for exporter in spanExporters {
        group.addTask {
          exporter.export(spans: spans, explicitTimeout: explicitTimeout)
        }
      }
      var currentResultCode = SpanExporterResultCode.success
      for await result in group {
        currentResultCode.mergeResultCode(newResultCode: result)
      }
      return currentResultCode
    }
  }

  public func flushAsync(explicitTimeout: TimeInterval? = nil) async -> SpanExporterResultCode {
    await withTaskGroup(of: SpanExporterResultCode.self, returning: SpanExporterResultCode.self) { group in
      for exporter in spanExporters {
        group.addTask {
          exporter.flush(explicitTimeout: explicitTimeout)
        }
      }
      var currentResultCode = SpanExporterResultCode.success
      for await result in group {
        currentResultCode.mergeResultCode(newResultCode: result)
      }
      return currentResultCode
    }
  }

  public func shutdownAsync(explicitTimeout: TimeInterval? = nil) async {
    await withTaskGroup(of: Void.self) { group in
      for exporter in spanExporters {
        group.addTask {
          exporter.shutdown(explicitTimeout: explicitTimeout)
        }
      }
    }
  }
}
