/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import OpenTelemetryApi
import OpenTelemetrySdk
import XCTest

// MARK: - Test Mocks

/// A sync-only exporter that also conforms to AsyncSpanExporter via defaults.
private class SyncOnlyAsyncSpanExporter: AsyncSpanExporter, @unchecked Sendable {
  var exportCalledTimes = 0
  var flushCalledTimes = 0
  var shutdownCalledTimes = 0
  var returnValue: SpanExporterResultCode = .success

  func export(spans: [SpanData], explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
    exportCalledTimes += 1
    return returnValue
  }

  func flush(explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
    flushCalledTimes += 1
    return returnValue
  }

  func shutdown(explicitTimeout: TimeInterval?) {
    shutdownCalledTimes += 1
  }
}

/// An exporter that overrides the async methods.
private class FullyAsyncSpanExporter: AsyncSpanExporter, @unchecked Sendable {
  var asyncExportCalledTimes = 0
  var asyncFlushCalledTimes = 0
  var asyncShutdownCalledTimes = 0
  var syncExportCalledTimes = 0
  var returnValue: SpanExporterResultCode = .success

  func export(spans: [SpanData], explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
    syncExportCalledTimes += 1
    return returnValue
  }

  func flush(explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
    return returnValue
  }

  func shutdown(explicitTimeout: TimeInterval?) {}

  func exportAsync(spans: [SpanData], explicitTimeout: TimeInterval?) async -> SpanExporterResultCode {
    asyncExportCalledTimes += 1
    return returnValue
  }

  func flushAsync(explicitTimeout: TimeInterval?) async -> SpanExporterResultCode {
    asyncFlushCalledTimes += 1
    return returnValue
  }

  func shutdownAsync(explicitTimeout: TimeInterval?) async {
    asyncShutdownCalledTimes += 1
  }
}

// MARK: - Tests

class AsyncSpanExporterTests: XCTestCase {
  private var spanList: [SpanData]!

  override func setUp() {
    spanList = [TestUtils.makeBasicSpan()]
  }

  // MARK: Default bridging tests

  func testDefaultBridgingExportCallsSyncMethod() async {
    let exporter = SyncOnlyAsyncSpanExporter()
    exporter.returnValue = .success
    let result = await exporter.exportAsync(spans: spanList)
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.exportCalledTimes, 1)
  }

  func testDefaultBridgingFlushCallsSyncMethod() async {
    let exporter = SyncOnlyAsyncSpanExporter()
    exporter.returnValue = .success
    let result = await exporter.flushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.flushCalledTimes, 1)
  }

  func testDefaultBridgingShutdownCallsSyncMethod() async {
    let exporter = SyncOnlyAsyncSpanExporter()
    await exporter.shutdownAsync()
    XCTAssertEqual(exporter.shutdownCalledTimes, 1)
  }

  func testDefaultBridgingPropagatesFailure() async {
    let exporter = SyncOnlyAsyncSpanExporter()
    exporter.returnValue = .failure
    let result = await exporter.exportAsync(spans: spanList)
    XCTAssertEqual(result, .failure)
  }

  // MARK: Async override tests

  func testAsyncOverrideExportCallsAsyncMethod() async {
    let exporter = FullyAsyncSpanExporter()
    exporter.returnValue = .success
    let result = await exporter.exportAsync(spans: spanList)
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.asyncExportCalledTimes, 1)
    XCTAssertEqual(exporter.syncExportCalledTimes, 0)
  }

  func testAsyncOverrideFlushCallsAsyncMethod() async {
    let exporter = FullyAsyncSpanExporter()
    let result = await exporter.flushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.asyncFlushCalledTimes, 1)
  }

  func testAsyncOverrideShutdownCallsAsyncMethod() async {
    let exporter = FullyAsyncSpanExporter()
    await exporter.shutdownAsync()
    XCTAssertEqual(exporter.asyncShutdownCalledTimes, 1)
  }

  // MARK: Convenience overload tests

  func testConvenienceExportWithoutTimeout() async {
    let exporter = SyncOnlyAsyncSpanExporter()
    let result = await exporter.exportAsync(spans: spanList)
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.exportCalledTimes, 1)
  }

  func testConvenienceFlushWithoutTimeout() async {
    let exporter = SyncOnlyAsyncSpanExporter()
    let result = await exporter.flushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.flushCalledTimes, 1)
  }

  func testConvenienceShutdownWithoutTimeout() async {
    let exporter = SyncOnlyAsyncSpanExporter()
    await exporter.shutdownAsync()
    XCTAssertEqual(exporter.shutdownCalledTimes, 1)
  }

  // MARK: MultiSpanExporter async tests

  func testMultiSpanExporterAsyncExportConcurrent() async {
    let exporter1 = FullyAsyncSpanExporter()
    let exporter2 = FullyAsyncSpanExporter()
    exporter1.returnValue = .success
    exporter2.returnValue = .success

    let multi = MultiSpanExporter(spanExporters: [exporter1, exporter2])
    let result = await multi.exportAsync(spans: spanList)
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter1.asyncExportCalledTimes, 1)
    XCTAssertEqual(exporter2.asyncExportCalledTimes, 1)
  }

  func testMultiSpanExporterAsyncExportMergesFailure() async {
    let exporter1 = FullyAsyncSpanExporter()
    let exporter2 = FullyAsyncSpanExporter()
    exporter1.returnValue = .success
    exporter2.returnValue = .failure

    let multi = MultiSpanExporter(spanExporters: [exporter1, exporter2])
    let result = await multi.exportAsync(spans: spanList)
    XCTAssertEqual(result, .failure)
  }

  func testMultiSpanExporterAsyncFlushConcurrent() async {
    let exporter1 = FullyAsyncSpanExporter()
    let exporter2 = FullyAsyncSpanExporter()

    let multi = MultiSpanExporter(spanExporters: [exporter1, exporter2])
    let result = await multi.flushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter1.asyncFlushCalledTimes, 1)
    XCTAssertEqual(exporter2.asyncFlushCalledTimes, 1)
  }

  func testMultiSpanExporterAsyncShutdownConcurrent() async {
    let exporter1 = FullyAsyncSpanExporter()
    let exporter2 = FullyAsyncSpanExporter()

    let multi = MultiSpanExporter(spanExporters: [exporter1, exporter2])
    await multi.shutdownAsync()
    XCTAssertEqual(exporter1.asyncShutdownCalledTimes, 1)
    XCTAssertEqual(exporter2.asyncShutdownCalledTimes, 1)
  }

  func testMultiSpanExporterMixedSyncAndAsyncExporters() async {
    let asyncExporter = FullyAsyncSpanExporter()
    let syncExporter = SyncOnlyAsyncSpanExporter()
    asyncExporter.returnValue = .success
    syncExporter.returnValue = .success

    let multi = MultiSpanExporter(spanExporters: [asyncExporter, syncExporter])
    let result = await multi.exportAsync(spans: spanList)
    XCTAssertEqual(result, .success)
    XCTAssertEqual(asyncExporter.asyncExportCalledTimes, 1)
    XCTAssertEqual(syncExporter.exportCalledTimes, 1)
  }

  func testSyncProcessorStillWorksWithAsyncExporter() {
    let exporter = FullyAsyncSpanExporter()
    exporter.returnValue = .success
    let result = exporter.export(spans: spanList)
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.syncExportCalledTimes, 1)
    XCTAssertEqual(exporter.asyncExportCalledTimes, 0)
  }
}
