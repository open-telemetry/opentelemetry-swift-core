/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import OpenTelemetryApi
@testable import OpenTelemetrySdk
import XCTest

// MARK: - Test Mocks

/// A sync-only exporter that also conforms to AsyncLogRecordExporter via defaults.
private class SyncOnlyAsyncLogExporter: AsyncLogRecordExporter, @unchecked Sendable {
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

/// An exporter that overrides the async methods.
private class FullyAsyncLogExporter: AsyncLogRecordExporter, @unchecked Sendable {
  var asyncExportCalledTimes = 0
  var asyncFlushCalledTimes = 0
  var asyncShutdownCalledTimes = 0
  var syncExportCalledTimes = 0
  var returnValue: ExportResult = .success

  func export(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval?) -> ExportResult {
    syncExportCalledTimes += 1
    return returnValue
  }

  func forceFlush(explicitTimeout: TimeInterval?) -> ExportResult {
    return returnValue
  }

  func shutdown(explicitTimeout: TimeInterval?) {}

  func exportAsync(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval?) async -> ExportResult {
    asyncExportCalledTimes += 1
    return returnValue
  }

  func forceFlushAsync(explicitTimeout: TimeInterval?) async -> ExportResult {
    asyncFlushCalledTimes += 1
    return returnValue
  }

  func shutdownAsync(explicitTimeout: TimeInterval?) async {
    asyncShutdownCalledTimes += 1
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
    let exporter = SyncOnlyAsyncLogExporter()
    exporter.returnValue = .success
    let result = await exporter.exportAsync(logRecords: [makeLogRecord()])
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.exportCalledTimes, 1)
  }

  func testDefaultBridgingFlushCallsSyncMethod() async {
    let exporter = SyncOnlyAsyncLogExporter()
    let result = await exporter.forceFlushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.flushCalledTimes, 1)
  }

  func testDefaultBridgingShutdownCallsSyncMethod() async {
    let exporter = SyncOnlyAsyncLogExporter()
    await exporter.shutdownAsync()
    XCTAssertEqual(exporter.shutdownCalledTimes, 1)
  }

  func testDefaultBridgingPropagatesFailure() async {
    let exporter = SyncOnlyAsyncLogExporter()
    exporter.returnValue = .failure
    let result = await exporter.exportAsync(logRecords: [makeLogRecord()])
    XCTAssertEqual(result, .failure)
  }

  // MARK: Async override tests

  func testAsyncOverrideExportCallsAsyncMethod() async {
    let exporter = FullyAsyncLogExporter()
    let result = await exporter.exportAsync(logRecords: [makeLogRecord()])
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.asyncExportCalledTimes, 1)
    XCTAssertEqual(exporter.syncExportCalledTimes, 0)
  }

  func testAsyncOverrideFlushCallsAsyncMethod() async {
    let exporter = FullyAsyncLogExporter()
    let result = await exporter.forceFlushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.asyncFlushCalledTimes, 1)
  }

  func testAsyncOverrideShutdownCallsAsyncMethod() async {
    let exporter = FullyAsyncLogExporter()
    await exporter.shutdownAsync()
    XCTAssertEqual(exporter.asyncShutdownCalledTimes, 1)
  }

  // MARK: Convenience overload tests

  func testConvenienceExportWithoutTimeout() async {
    let exporter = SyncOnlyAsyncLogExporter()
    let result = await exporter.exportAsync(logRecords: [makeLogRecord()])
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.exportCalledTimes, 1)
  }

  func testConvenienceFlushWithoutTimeout() async {
    let exporter = SyncOnlyAsyncLogExporter()
    let result = await exporter.forceFlushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.flushCalledTimes, 1)
  }

  func testConvenienceShutdownWithoutTimeout() async {
    let exporter = SyncOnlyAsyncLogExporter()
    await exporter.shutdownAsync()
    XCTAssertEqual(exporter.shutdownCalledTimes, 1)
  }

  // MARK: MultiLogRecordExporter async tests

  func testMultiLogExporterAsyncExportConcurrent() async {
    let exporter1 = FullyAsyncLogExporter()
    let exporter2 = FullyAsyncLogExporter()

    let multi = MultiLogRecordExporter(logRecordExporters: [exporter1, exporter2])
    let result = await multi.exportAsync(logRecords: [makeLogRecord()])
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter1.asyncExportCalledTimes, 1)
    XCTAssertEqual(exporter2.asyncExportCalledTimes, 1)
  }

  func testMultiLogExporterAsyncExportMergesFailure() async {
    let exporter1 = FullyAsyncLogExporter()
    let exporter2 = FullyAsyncLogExporter()
    exporter1.returnValue = .success
    exporter2.returnValue = .failure

    let multi = MultiLogRecordExporter(logRecordExporters: [exporter1, exporter2])
    let result = await multi.exportAsync(logRecords: [makeLogRecord()])
    XCTAssertEqual(result, .failure)
  }

  func testMultiLogExporterAsyncFlushConcurrent() async {
    let exporter1 = FullyAsyncLogExporter()
    let exporter2 = FullyAsyncLogExporter()

    let multi = MultiLogRecordExporter(logRecordExporters: [exporter1, exporter2])
    let result = await multi.forceFlushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter1.asyncFlushCalledTimes, 1)
    XCTAssertEqual(exporter2.asyncFlushCalledTimes, 1)
  }

  func testMultiLogExporterAsyncShutdownConcurrent() async {
    let exporter1 = FullyAsyncLogExporter()
    let exporter2 = FullyAsyncLogExporter()

    let multi = MultiLogRecordExporter(logRecordExporters: [exporter1, exporter2])
    await multi.shutdownAsync()
    XCTAssertEqual(exporter1.asyncShutdownCalledTimes, 1)
    XCTAssertEqual(exporter2.asyncShutdownCalledTimes, 1)
  }

  func testMultiLogExporterMixedSyncAndAsyncExporters() async {
    let asyncExporter = FullyAsyncLogExporter()
    let syncExporter = SyncOnlyAsyncLogExporter()

    let multi = MultiLogRecordExporter(logRecordExporters: [asyncExporter, syncExporter])
    let result = await multi.exportAsync(logRecords: [makeLogRecord()])
    XCTAssertEqual(result, .success)
    XCTAssertEqual(asyncExporter.asyncExportCalledTimes, 1)
    XCTAssertEqual(syncExporter.exportCalledTimes, 1)
  }

  func testSyncProcessorStillWorksWithAsyncExporter() {
    let exporter = FullyAsyncLogExporter()
    let result = exporter.export(logRecords: [makeLogRecord()])
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.syncExportCalledTimes, 1)
    XCTAssertEqual(exporter.asyncExportCalledTimes, 0)
  }
}
