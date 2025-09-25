//
// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import OpenTelemetryApi

final class LogRecordBuilderDefaultImplementationTests: XCTestCase {
  
  func testSetEventNameDefaultImplementation() {
    let builder = MockLogRecordBuilder()
    
    let result = builder.setEventName("test.event")
    
    XCTAssertTrue(result === builder, "Default setEventName implementation should return self")
  }
}

private class MockLogRecordBuilder: LogRecordBuilder {
  func setTimestamp(_ timestamp: Date) -> Self { return self }
  func setObservedTimestamp(_ observed: Date) -> Self { return self }
  func setSpanContext(_ context: SpanContext) -> Self { return self }
  func setSeverity(_ severity: Severity) -> Self { return self }
  func setBody(_ body: AttributeValue) -> Self { return self }
  func setAttributes(_ attributes: [String: AttributeValue]) -> Self { return self }
  func emit() {}
}