/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import OpenTelemetryApi
@testable import OpenTelemetrySdk
import XCTest

// MARK: - Test Mocks

/// A sync-only exporter that also conforms to AsyncMetricExporter via defaults.
private class SyncOnlyAsyncMetricExporter: AsyncMetricExporter, @unchecked Sendable {
  var exportCalledTimes = 0
  var flushCalledTimes = 0
  var shutdownCalledTimes = 0
  var returnValue: ExportResult = .success

  func export(metrics: [MetricData]) -> ExportResult {
    exportCalledTimes += 1
    return returnValue
  }

  func flush() -> ExportResult {
    flushCalledTimes += 1
    return returnValue
  }

  func shutdown() -> ExportResult {
    shutdownCalledTimes += 1
    return returnValue
  }

  func getAggregationTemporality(for instrument: InstrumentType) -> AggregationTemporality {
    return .cumulative
  }
}

/// An exporter that overrides the async methods.
private class FullyAsyncMetricExporter: AsyncMetricExporter, @unchecked Sendable {
  var asyncExportCalledTimes = 0
  var asyncFlushCalledTimes = 0
  var asyncShutdownCalledTimes = 0
  var syncExportCalledTimes = 0
  var returnValue: ExportResult = .success

  func export(metrics: [MetricData]) -> ExportResult {
    syncExportCalledTimes += 1
    return returnValue
  }

  func flush() -> ExportResult {
    return returnValue
  }

  func shutdown() -> ExportResult {
    return returnValue
  }

  func getAggregationTemporality(for instrument: InstrumentType) -> AggregationTemporality {
    return .cumulative
  }

  func exportAsync(metrics: [MetricData]) async -> ExportResult {
    asyncExportCalledTimes += 1
    return returnValue
  }

  func flushAsync() async -> ExportResult {
    asyncFlushCalledTimes += 1
    return returnValue
  }

  func shutdownAsync() async -> ExportResult {
    asyncShutdownCalledTimes += 1
    return returnValue
  }
}

// MARK: - Tests

class AsyncMetricExporterTests: XCTestCase {
  // MARK: Default bridging tests

  func testDefaultBridgingExportCallsSyncMethod() async {
    let exporter = SyncOnlyAsyncMetricExporter()
    exporter.returnValue = .success
    let result = await exporter.exportAsync(metrics: [MetricData.empty])
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.exportCalledTimes, 1)
  }

  func testDefaultBridgingFlushCallsSyncMethod() async {
    let exporter = SyncOnlyAsyncMetricExporter()
    let result = await exporter.flushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.flushCalledTimes, 1)
  }

  func testDefaultBridgingShutdownCallsSyncMethod() async {
    let exporter = SyncOnlyAsyncMetricExporter()
    let result = await exporter.shutdownAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.shutdownCalledTimes, 1)
  }

  func testDefaultBridgingPropagatesFailure() async {
    let exporter = SyncOnlyAsyncMetricExporter()
    exporter.returnValue = .failure
    let result = await exporter.exportAsync(metrics: [MetricData.empty])
    XCTAssertEqual(result, .failure)
  }

  // MARK: Async override tests

  func testAsyncOverrideExportCallsAsyncMethod() async {
    let exporter = FullyAsyncMetricExporter()
    let result = await exporter.exportAsync(metrics: [MetricData.empty])
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.asyncExportCalledTimes, 1)
    XCTAssertEqual(exporter.syncExportCalledTimes, 0)
  }

  func testAsyncOverrideFlushCallsAsyncMethod() async {
    let exporter = FullyAsyncMetricExporter()
    let result = await exporter.flushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.asyncFlushCalledTimes, 1)
  }

  func testAsyncOverrideShutdownCallsAsyncMethod() async {
    let exporter = FullyAsyncMetricExporter()
    let result = await exporter.shutdownAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.asyncShutdownCalledTimes, 1)
  }

  // MARK: Sync processor compatibility

  func testSyncProcessorStillWorksWithAsyncExporter() {
    let exporter = FullyAsyncMetricExporter()
    let result = exporter.export(metrics: [MetricData.empty])
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.syncExportCalledTimes, 1)
    XCTAssertEqual(exporter.asyncExportCalledTimes, 0)
  }
}
