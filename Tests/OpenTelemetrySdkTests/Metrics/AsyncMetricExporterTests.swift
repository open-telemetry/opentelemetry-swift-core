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
private class SyncOnlyMetricExporter: MetricExporter, @unchecked Sendable {
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

// MARK: - Tests

class AsyncMetricExporterTests: XCTestCase {
  // MARK: Default bridging tests

  func testDefaultBridgingExportCallsSyncMethod() async {
    let exporter = SyncOnlyMetricExporter()
    exporter.returnValue = .success
    let result = await exporter.exportAsync(metrics: [MetricData.empty])
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.exportCalledTimes, 1)
  }

  func testDefaultBridgingFlushCallsSyncMethod() async {
    let exporter = SyncOnlyMetricExporter()
    let result = await exporter.flushAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.flushCalledTimes, 1)
  }

  func testDefaultBridgingShutdownCallsSyncMethod() async {
    let exporter = SyncOnlyMetricExporter()
    let result = await exporter.shutdownAsync()
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.shutdownCalledTimes, 1)
  }

  func testDefaultBridgingPropagatesFailure() async {
    let exporter = SyncOnlyMetricExporter()
    exporter.returnValue = .failure
    let result = await exporter.exportAsync(metrics: [MetricData.empty])
    XCTAssertEqual(result, .failure)
  }

  // MARK: Sync compatibility

  func testSyncMethodsStillWork() {
    let exporter = SyncOnlyMetricExporter()
    let result = exporter.export(metrics: [MetricData.empty])
    XCTAssertEqual(result, .success)
    XCTAssertEqual(exporter.exportCalledTimes, 1)
  }
}
