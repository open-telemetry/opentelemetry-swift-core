//
// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0
//
import OpenTelemetryApi
@testable import OpenTelemetrySdk
import XCTest

class MeterProviderSdkTests: XCTestCase {
  var meterProvider = MeterProviderSdk.builder().build()

  func testGetSameInstanceForName_WithoutVersion() {
    XCTAssert(meterProvider.get(name: "test") as AnyObject === meterProvider.get(name: "test") as AnyObject)
    XCTAssert(meterProvider.get(name: "test") as AnyObject === meterProvider.meterBuilder(name: "test").build() as AnyObject)
  }

  func testDefaultViewAppliedWhenNoViewsRegistered() {
    let exporter = WaitingMetricExporter(numberToWaitFor: 1, aggregationTemporality: .delta)
    let provider = MeterProviderSdk.builder()
      .registerMetricReader(reader: PeriodicMetricReaderSdk(exporter: exporter, exportInterval: 60.0))
      .build()
    let meter = provider.meterBuilder(name: "default-view-test").build()
    let histogram = meter.histogramBuilder(name: "test.latency_ms").build()
    histogram.record(value: 42)
    histogram.record(value: 17)

    XCTAssertEqual(provider.forceFlush(), .success)
    let metrics = exporter.waitForExport()
    XCTAssertEqual(metrics.count, 1)
    XCTAssertEqual(metrics.first?.name, "test.latency_ms")
    XCTAssertEqual(metrics.first?.getHistogramData().first?.count, 2)
  }
}
