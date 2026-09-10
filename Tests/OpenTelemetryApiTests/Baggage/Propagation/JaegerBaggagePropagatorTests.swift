/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

@testable import OpenTelemetryApi
import XCTest

class JaegerBaggagePropagatorTests: XCTestCase {
  let builder = DefaultBaggageBuilder()
  let jaegerPropagator = JaegerBaggagePropagator()
  let setter = TestSetter()
  let getter = TestGetter()

  func testInjectBaggage() {
    // Metadata won't be propagated, but it MUST NOT cause ay problem.
    let baggage = builder.put(key: "nometa", value: "nometa-value")
      .put(key: "nometa", value: "nometa-value")
      .put(key: "meta", value: "meta-value", metadata: "somemetadata; someother=foo")
      .build()

    var carrier = [String: String]()
    jaegerPropagator.inject(baggage: baggage, carrier: &carrier, setter: setter)

    let expected1 = [JaegerBaggagePropagator.baggagePrefix + "nometa": "nometa-value",
                     JaegerBaggagePropagator.baggagePrefix + "meta": "meta-value"]
    let expected2 = [JaegerBaggagePropagator.baggagePrefix + "meta": "meta-value",
                     JaegerBaggagePropagator.baggagePrefix + "nometa": "nometa-value"]
    XCTAssert(carrier == expected1 || carrier == expected2)
  }

  func testExtractBaggageWithPrefix() {
    var carrier = [String: String]()
    carrier[JaegerBaggagePropagator.baggagePrefix + "nometa"] = "nometa-value"
    carrier[JaegerBaggagePropagator.baggagePrefix + "meta"] = "meta-value"
    carrier["another"] = "value"

    let expectedBaggage = builder.put(key: "nometa", value: "nometa-value")
      .put(key: "meta", value: "meta-value")
      .build()

    let result = jaegerPropagator.extract(carrier: carrier, getter: getter)
    XCTAssertEqual(result?.getEntries().sorted(), expectedBaggage.getEntries().sorted())
  }

  func testExtractBaggageWithPrefixEmptyKey() {
    var carrier = [String: String]()
    carrier[JaegerBaggagePropagator.baggagePrefix] = "value"

    let result = jaegerPropagator.extract(carrier: carrier, getter: getter)!
    XCTAssertTrue(result.getEntries().isEmpty)
  }

  func testExtractBaggageWithHeader() {
    var carrier = [String: String]()
    carrier[JaegerBaggagePropagator.baggageHeader] = "nometa=nometa-value,meta=meta-value"

    let expectedBaggage = builder.put(key: "nometa", value: "nometa-value")
      .put(key: "meta", value: "meta-value")
      .build()

    let result = jaegerPropagator.extract(carrier: carrier, getter: getter)
    XCTAssertEqual(result?.getEntries().sorted(), expectedBaggage.getEntries().sorted())
  }

  func testExtractBaggageWithHeaderAndSpaces() {
    var carrier = [String: String]()
    carrier[JaegerBaggagePropagator.baggageHeader] = "nometa = nometa-value , meta = meta-value"

    let expectedBaggage = builder.put(key: "nometa", value: "nometa-value")
      .put(key: "meta", value: "meta-value")
      .build()

    let result = jaegerPropagator.extract(carrier: carrier, getter: getter)
    XCTAssertEqual(result?.getEntries().sorted(), expectedBaggage.getEntries().sorted())
  }

  func testExtractBaggageWithHeaderInvalid() {
    var carrier = [String: String]()
    carrier[JaegerBaggagePropagator.baggageHeader] = "nometa+novalue"

    let result = jaegerPropagator.extract(carrier: carrier, getter: getter)
    XCTAssertTrue(result?.getEntries().isEmpty ?? false)
  }

  func testExtractBaggageWithHeaderAndPrefix() {
    var carrier = [String: String]()
    carrier[JaegerBaggagePropagator.baggageHeader] = "nometa=nometa-value,meta=meta-value"
    carrier[JaegerBaggagePropagator.baggagePrefix + "foo"] = "bar"

    let expectedBaggage = builder.put(key: "nometa", value: "nometa-value")
      .put(key: "meta", value: "meta-value")
      .put(key: "foo", value: "bar")
      .build()

    let result = jaegerPropagator.extract(carrier: carrier, getter: getter)
    XCTAssertEqual(result?.getEntries().sorted(), expectedBaggage.getEntries().sorted())
  }

  // MARK: - Limits borrowed from W3C Baggage (https://www.w3.org/TR/baggage/#limits)

  func testExtractMaxEntriesWithPrefix() {
    var carrier = [String: String]()
    for index in 0 ..< 65 {
      carrier[JaegerBaggagePropagator.baggagePrefix + "k\(index)"] = "v"
    }

    let result = jaegerPropagator.extract(carrier: carrier, getter: getter)!
    XCTAssertEqual(result.getEntries().count, 64)
  }

  func testExtractExactlyMaxEntriesWithPrefix() {
    var carrier = [String: String]()
    for index in 0 ..< 64 {
      carrier[JaegerBaggagePropagator.baggagePrefix + "k\(index)"] = "v"
    }

    let result = jaegerPropagator.extract(carrier: carrier, getter: getter)!
    XCTAssertEqual(result.getEntries().count, 64)
  }

  func testExtractMaxEntriesWithHeader() {
    var carrier = [String: String]()
    carrier[JaegerBaggagePropagator.baggageHeader] = (0 ..< 65).map { "k\($0)=v" }.joined(separator: ",")

    let result = jaegerPropagator.extract(carrier: carrier, getter: getter)!
    XCTAssertEqual(result.getEntries().count, 64)
  }

  func testExtractPrefixAndHeaderShareLimit() {
    var carrier = [String: String]()
    for index in 0 ..< 40 {
      carrier[JaegerBaggagePropagator.baggagePrefix + "p\(index)"] = "v"
    }
    carrier[JaegerBaggagePropagator.baggageHeader] = (0 ..< 40).map { "h\($0)=v" }.joined(separator: ",")

    let result = jaegerPropagator.extract(carrier: carrier, getter: getter)!
    XCTAssertEqual(result.getEntries().count, 64)
  }

  func testExtractMaxBytes() {
    // 32 entries of 260 bytes are 8320 bytes. 31 fit (8060), the 32nd does not.
    var carrier = [String: String]()
    for index in 0 ..< 32 {
      carrier[JaegerBaggagePropagator.baggagePrefix + String(format: "key%07d", index)] = String(repeating: "v", count: 250)
    }

    let result = jaegerPropagator.extract(carrier: carrier, getter: getter)!
    XCTAssertEqual(result.getEntries().count, 31)
  }
}
