/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import OpenTelemetryApi
import OpenTelemetrySdk
import XCTest

// MARK: - Test Mocks

/// A sync-only exporter — async methods use the default bridging from the extension.
private class SyncOnlySpanExporter: SpanExporter, @unchecked Sendable {
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

// MARK: - Tests

class AsyncSpanExporterTests: XCTestCase {
  private var spanList: [SpanData]!

  override func setUp() {
    spanList = [TestUtils.makeBasicSpan()]
  }

  // MARK: Default bridging tests

  func testDefaultBridgingExportCallsSyncMethod() async {
    let exporter = SyncOnlySpanExporter()
    exporter.returnValue = .success
    let result = await exporter.exportAsync(spans: spanList)
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.exportCalledTimes, 1)
  }

  func testDefaultBridgingFlushCallsSyncMethod() async {
    let exporter = SyncOnlySpanExporter()
    exporter.returnValue = .success
    let result = await exporter.flushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.flushCalledTimes, 1)
  }

  func testDefaultBridgingShutdownCallsSyncMethod() async {
    let exporter = SyncOnlySpanExporter()
    await exporter.shutdownAsync()
    XCTAssertEqual(exporter.shutdownCalledTimes, 1)
  }

  func testDefaultBridgingPropagatesFailure() async {
    let exporter = SyncOnlySpanExporter()
    exporter.returnValue = .failure
    let result = await exporter.exportAsync(spans: spanList)
    XCTAssertEqual(result, .failure)
  }

  // MARK: Convenience overload tests

  func testConvenienceExportWithoutTimeout() async {
    let exporter = SyncOnlySpanExporter()
    let result = await exporter.exportAsync(spans: spanList)
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.exportCalledTimes, 1)
  }

  func testConvenienceFlushWithoutTimeout() async {
    let exporter = SyncOnlySpanExporter()
    let result = await exporter.flushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.flushCalledTimes, 1)
  }

  func testConvenienceShutdownWithoutTimeout() async {
    let exporter = SyncOnlySpanExporter()
    await exporter.shutdownAsync()
    XCTAssertEqual(exporter.shutdownCalledTimes, 1)
  }

  // MARK: MultiSpanExporter async tests

  func testMultiSpanExporterAsyncExportConcurrent() async {
    let exporter1 = SyncOnlySpanExporter()
    let exporter2 = SyncOnlySpanExporter()

    let multi = MultiSpanExporter(spanExporters: [exporter1, exporter2])
    let result = await multi.exportAsync(spans: spanList)
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter1.exportCalledTimes, 1)
    XCTAssertEqual(exporter2.exportCalledTimes, 1)
  }

  func testMultiSpanExporterAsyncExportMergesFailure() async {
    let exporter1 = SyncOnlySpanExporter()
    let exporter2 = SyncOnlySpanExporter()
    exporter1.returnValue = .success
    exporter2.returnValue = .failure

    let multi = MultiSpanExporter(spanExporters: [exporter1, exporter2])
    let result = await multi.exportAsync(spans: spanList)
    XCTAssertEqual(result, .failure)
  }

  func testMultiSpanExporterAsyncFlushConcurrent() async {
    let exporter1 = SyncOnlySpanExporter()
    let exporter2 = SyncOnlySpanExporter()

    let multi = MultiSpanExporter(spanExporters: [exporter1, exporter2])
    let result = await multi.flushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter1.flushCalledTimes, 1)
    XCTAssertEqual(exporter2.flushCalledTimes, 1)
  }

  func testMultiSpanExporterAsyncShutdownConcurrent() async {
    let exporter1 = SyncOnlySpanExporter()
    let exporter2 = SyncOnlySpanExporter()

    let multi = MultiSpanExporter(spanExporters: [exporter1, exporter2])
    await multi.shutdownAsync()
    XCTAssertEqual(exporter1.shutdownCalledTimes, 1)
    XCTAssertEqual(exporter2.shutdownCalledTimes, 1)
  }

  // MARK: Sync compatibility

  func testSyncMethodsStillWork() {
    let exporter = SyncOnlySpanExporter()
    exporter.returnValue = .success
    let result = exporter.export(spans: spanList)
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.exportCalledTimes, 1)
  }
}
