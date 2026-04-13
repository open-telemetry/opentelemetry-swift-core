/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import OpenTelemetryApi
@testable import OpenTelemetrySdk
import XCTest

// MARK: - Test Mocks

/// An exporter that provides native async implementations.
private class AsyncCapableLogExporter: LogRecordExporter {
  var exportAsyncCalledTimes = 0
  var flushAsyncCalledTimes = 0
  var shutdownAsyncCalledTimes = 0
  var returnValue: ExportResult = .success

  func export(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval?) -> ExportResult {
    fatalError("Sync export should not be called on an async-capable exporter")
  }

  func forceFlush(explicitTimeout: TimeInterval?) -> ExportResult {
    fatalError("Sync forceFlush should not be called on an async-capable exporter")
  }

  func shutdown(explicitTimeout: TimeInterval?) {
    fatalError("Sync shutdown should not be called on an async-capable exporter")
  }

  func exportAsync(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval?) async -> ExportResult {
    exportAsyncCalledTimes += 1
    return returnValue
  }

  func forceFlushAsync(explicitTimeout: TimeInterval?) async -> ExportResult {
    flushAsyncCalledTimes += 1
    return returnValue
  }

  func shutdownAsync(explicitTimeout: TimeInterval?) async {
    shutdownAsyncCalledTimes += 1
  }
}

/// A sync-only exporter used for MultiLogRecordExporter tests and sync compatibility.
private class SyncOnlyLogExporter: LogRecordExporter, @unchecked Sendable {
  var exportCalledTimes = 0
  var flushCalledTimes = 0
  var shutdownCalledTimes = 0
  var returnValue: ExportResult = .success

  func export(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval?) -> ExportResult {
    exportCalledTimes += 1
    return returnValue
  }

  func forceFlush(explicitTimeout: TimeInterval?) -> ExportResult {
    flushCalledTimes += 1
    return returnValue
  }

  func shutdown(explicitTimeout: TimeInterval?) {
    shutdownCalledTimes += 1
  }
}

// MARK: - Helper

private func makeLogRecord() -> ReadableLogRecord {
  return ReadableLogRecord(
    resource: Resource(),
    instrumentationScopeInfo: InstrumentationScopeInfo(name: "test"),
    timestamp: Date(),
    attributes: [String: AttributeValue]()
  )
}

// MARK: - Tests

class AsyncLogRecordExporterTests: XCTestCase {
  // MARK: Async-capable exporter tests

  func testAsyncExporterExport() async {
    let exporter = AsyncCapableLogExporter()
    exporter.returnValue = .success
    let result = await exporter.exportAsync(logRecords: [makeLogRecord()])
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.exportAsyncCalledTimes, 1)
  }

  func testAsyncExporterFlush() async {
    let exporter = AsyncCapableLogExporter()
    let result = await exporter.forceFlushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.flushAsyncCalledTimes, 1)
  }

  func testAsyncExporterShutdown() async {
    let exporter = AsyncCapableLogExporter()
    await exporter.shutdownAsync()
    XCTAssertEqual(exporter.shutdownAsyncCalledTimes, 1)
  }

  func testAsyncExporterPropagatesFailure() async {
    let exporter = AsyncCapableLogExporter()
    exporter.returnValue = .failure
    let result = await exporter.exportAsync(logRecords: [makeLogRecord()])
    XCTAssertEqual(result, .failure)
  }

  // MARK: MultiLogRecordExporter async tests

  func testMultiLogExporterAsyncExport() async {
    let exporter1 = SyncOnlyLogExporter()
    let exporter2 = SyncOnlyLogExporter()

    let multi = MultiLogRecordExporter(logRecordExporters: [exporter1, exporter2])
    let result = await multi.exportAsync(logRecords: [makeLogRecord()])
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter1.exportCalledTimes, 1)
    XCTAssertEqual(exporter2.exportCalledTimes, 1)
  }

  func testMultiLogExporterAsyncExportMergesFailure() async {
    let exporter1 = SyncOnlyLogExporter()
    let exporter2 = SyncOnlyLogExporter()
    exporter1.returnValue = .success
    exporter2.returnValue = .failure

    let multi = MultiLogRecordExporter(logRecordExporters: [exporter1, exporter2])
    let result = await multi.exportAsync(logRecords: [makeLogRecord()])
    XCTAssertEqual(result, .failure)
  }

  func testMultiLogExporterAsyncFlush() async {
    let exporter1 = SyncOnlyLogExporter()
    let exporter2 = SyncOnlyLogExporter()

    let multi = MultiLogRecordExporter(logRecordExporters: [exporter1, exporter2])
    let result = await multi.forceFlushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter1.flushCalledTimes, 1)
    XCTAssertEqual(exporter2.flushCalledTimes, 1)
  }

  func testMultiLogExporterAsyncShutdown() async {
    let exporter1 = SyncOnlyLogExporter()
    let exporter2 = SyncOnlyLogExporter()

    let multi = MultiLogRecordExporter(logRecordExporters: [exporter1, exporter2])
    await multi.shutdownAsync()
    XCTAssertEqual(exporter1.shutdownCalledTimes, 1)
    XCTAssertEqual(exporter2.shutdownCalledTimes, 1)
  }

  // MARK: Sync compatibility

  func testSyncMethodsStillWork() {
    let exporter = SyncOnlyLogExporter()
    let result = exporter.export(logRecords: [makeLogRecord()])
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.exportCalledTimes, 1)
  }
}
