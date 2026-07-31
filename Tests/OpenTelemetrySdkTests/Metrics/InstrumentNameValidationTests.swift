//
// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0
//

@testable import OpenTelemetryApi
@testable import OpenTelemetrySdk
import XCTest

class InstrumentNameValidationTests: XCTestCase {
  func testAcceptsConformingNames() {
    let names = [
      "a",
      "counter",
      "http.server.request.duration",
      "queue_size",
      "cache-hits",
      "system/cpu/time",
      "a1",
      "A_mixed.Case-name/1",
      String(repeating: "a", count: InstrumentBuilder.maximumNameLength),
    ]
    for name in names {
      XCTAssertTrue(InstrumentBuilder.isValidName(name), "expected \"\(name)\" to be valid")
    }
  }

  func testRejectsNonConformingNames() {
    let names = [
      "",                                                                  // empty
      "1counter",                                                          // leading digit
      "_counter",                                                          // leading underscore
      ".counter",                                                          // leading period
      "-counter",                                                          // leading hyphen
      "/counter",                                                          // leading slash
      "requests per second",                                               // space
      "requests%",                                                         // disallowed punctuation
      "requests:total",                                                    // disallowed punctuation
      "café.requests",                                                     // non-ASCII
      String(repeating: "a", count: InstrumentBuilder.maximumNameLength + 1), // too long
    ]
    for name in names {
      XCTAssertFalse(InstrumentBuilder.isValidName(name), "expected \"\(name)\" to be invalid")
    }
  }

  func testBuildingInstrumentWithInvalidNameReportsFeedback() {
    let original = OpenTelemetry.instance.feedbackHandler
    defer { if let original { OpenTelemetry.registerFeedbackHandler(original) } }

    var messages: [String] = []
    OpenTelemetry.registerFeedbackHandler { messages.append($0) }

    let meter = Self.makeSdkMeter()
    _ = meter.counterBuilder(name: "1invalid").build()

    XCTAssertEqual(messages.count, 1)
    XCTAssertTrue(messages.first?.contains("1invalid") == true)
    XCTAssertTrue(messages.first?.contains("does not conform") == true)
  }

  func testBuildingInstrumentWithValidNameReportsNothing() {
    let original = OpenTelemetry.instance.feedbackHandler
    defer { if let original { OpenTelemetry.registerFeedbackHandler(original) } }

    var messages: [String] = []
    OpenTelemetry.registerFeedbackHandler { messages.append($0) }

    let meter = Self.makeSdkMeter()
    _ = meter.counterBuilder(name: "valid.counter").build()

    XCTAssertTrue(messages.isEmpty, "unexpected feedback: \(messages)")
  }

  /// A meter backed by `MeterSdk`. Without a registered reader the provider hands back a
  /// `DefaultMeter`, which never reaches `InstrumentBuilder`.
  private static func makeSdkMeter() -> any Meter {
    let reader = PeriodicMetricReaderBuilder(exporter: MockMetricExporter()).build()
    return MeterProviderSdk.builder()
      .registerMetricReader(reader: reader)
      .build()
      .meterBuilder(name: "InstrumentNameValidationTests")
      .build()
  }
}
