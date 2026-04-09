/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import OpenTelemetryApi
@testable import OpenTelemetrySdk
import XCTest

// MARK: - Test Mocks

/// A sync-only exporter — async methods use the default bridging from the extension.
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
  // MARK: Default bridging tests

  func testDefaultBridgingExportCallsSyncMethod() async {
    let exporter = SyncOnlyLogExporter()
    exporter.returnValue = .success
    let result = await exporter.exportAsync(logRecords: [makeLogRecord()])
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.exportCalledTimes, 1)
  }

  func testDefaultBridgingFlushCallsSyncMethod() async {
    let exporter = SyncOnlyLogExporter()
    let result = await exporter.forceFlushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.flushCalledTimes, 1)
  }

  func testDefaultBridgingShutdownCallsSyncMethod() async {
    let exporter = SyncOnlyLogExporter()
    await exporter.shutdownAsync()
    XCTAssertEqual(exporter.shutdownCalledTimes, 1)
  }

  func testDefaultBridgingPropagatesFailure() async {
    let exporter = SyncOnlyLogExporter()
    exporter.returnValue = .failure
    let result = await exporter.exportAsync(logRecords: [makeLogRecord()])
    XCTAssertEqual(result, .failure)
  }

  // MARK: Convenience overload tests

  func testConvenienceExportWithoutTimeout() async {
    let exporter = SyncOnlyLogExporter()
    let result = await exporter.exportAsync(logRecords: [makeLogRecord()])
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.exportCalledTimes, 1)
  }

  func testConvenienceFlushWithoutTimeout() async {
    let exporter = SyncOnlyLogExporter()
    let result = await exporter.forceFlushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.flushCalledTimes, 1)
  }

  func testConvenienceShutdownWithoutTimeout() async {
    let exporter = SyncOnlyLogExporter()
    await exporter.shutdownAsync()
    XCTAssertEqual(exporter.shutdownCalledTimes, 1)
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
