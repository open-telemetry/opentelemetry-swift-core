/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public extension TimeInterval {
  /// `TimeInterval` represented in milliseconds (clamped to [`0`, `UInt64.max`]).
  var toMilliseconds: UInt64 {
    let milliseconds = self * 1_000
    return UInt64(withReportingOverflow: milliseconds) ?? (self < 0 ? .min : .max)
  }

  /// `TimeInterval` represented in microseconds (clamped to [`0`, `UInt64.max`]).
  var toMicroseconds: UInt64 {
    let microseconds = self * 1_000_000
    return UInt64(withReportingOverflow: microseconds) ?? (self < 0 ? .min : .max)
  }

  /// `TimeInterval` represented in nanoseconds (clamped to [`0`, `UInt64.max`]).
  var toNanoseconds: UInt64 {
    let nanoseconds = self * 1_000_000_000
    return UInt64(withReportingOverflow: nanoseconds) ?? (self < 0 ? .min : .max)
  }

  static func fromMilliseconds(_ millis: Int64) -> TimeInterval {
    return Double(millis) / 1_000
  }

  static func fromMicroseconds(_ micros: Int64) -> TimeInterval {
    return Double(micros) / 1_000_000
  }

  static func fromNanoseconds(_ nanos: Int64) -> TimeInterval {
    return Double(nanos) / 1_000_000_000
  }
  
  /// `TimeInterval` represented in milliseconds (clamped to [`Int64.min`, `Int64.max`]).
  var toSignedMilliseconds: Int64 {
    let milliseconds = self * 1_000
    return Int64(withReportingOverflow: milliseconds) ?? (self < 0 ? .min : .max)
  }

  /// `TimeInterval` represented in microseconds (clamped to [`Int64.min`, `Int64.max`]).
  var toSignedMicroseconds: Int64 {
    let microseconds = self * 1_000_000
    return Int64(withReportingOverflow: microseconds) ?? (self < 0 ? .min : .max)
  }

  /// `TimeInterval` represented in nanoseconds (clamped to [`Int64.min`, `Int64.max`]).
  var toSignedNanoseconds: Int64 {
    let nanoseconds = self * 1_000_000_000
    return Int64(withReportingOverflow: nanoseconds) ?? (self < 0 ? .min : .max)
  }

  static func fromSignedMilliseconds(_ millis: Int64) -> TimeInterval {
    return Double(millis) / 1_000
  }

  static func fromSignedMicroseconds(_ micros: Int64) -> TimeInterval {
    return Double(micros) / 1_000_000
  }

  static func fromSignedNanoseconds(_ nanos: Int64) -> TimeInterval {
    return Double(nanos) / 1_000_000_000
  }
}

private extension FixedWidthInteger {
  init?(withReportingOverflow floatingPoint: some BinaryFloatingPoint) {
    guard let converted = Self(exactly: floatingPoint.rounded()) else {
      return nil
    }
    self = converted
  }
}
