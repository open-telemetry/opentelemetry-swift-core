/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public class DefaultLogger: Logger {
  private static let instanceWithDomain = DefaultLogger(true)
  private static let instanceNoDomain = DefaultLogger(false)
  private static let noopLogRecordBuilder = NoopLogRecordBuilder()

  private var hasDomain: Bool

  private init(_ hasDomain: Bool) {
    self.hasDomain = hasDomain
  }

  static func getInstance(_ hasDomain: Bool) -> Logger {
    if hasDomain {
      return instanceWithDomain
    } else {
      return instanceNoDomain
    }
  }

  public func eventBuilder(name: String) -> EventBuilder {
    if !hasDomain {
      /// log error
    }
    return Self.noopLogRecordBuilder
  }

  public func logRecordBuilder() -> LogRecordBuilder {
    return Self.noopLogRecordBuilder
  }

  private class NoopLogRecordBuilder: EventBuilder {}
}
