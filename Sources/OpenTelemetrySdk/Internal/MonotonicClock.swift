/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import OpenTelemetryApi

/// A clock that provides monotonic time tracking by combining wall clock time with DispatchTime.
/// This clock is immune to system clock adjustments (NTP, user changes, etc.) and never goes backwards.
///
/// This clock should be re-created periodically to re-sync with the system clock, as it tracks
/// elapsed time from initialization and can drift from actual wall clock time over long periods.
public class MonotonicClock: Clock {
  let clock: Clock
  let initialWallTimeNanos: Int64
  let initialMonotonicNanos: Int64

  public init(clock: Clock) {
    self.clock = clock

    // Capture both wall time and monotonic time as close together as possible
    let wallTime = clock.nanoTime
    let monotonicNanos = clock.monotonicNanos

    self.initialWallTimeNanos = wallTime
    self.initialMonotonicNanos = monotonicNanos
  }

  public var nanoTime: Int64 {
    // Adjust the initial wall time by however many nanos have passed since then.
    let currentMonotonicNanos = clock.monotonicNanos
    let elapsedNanos = currentMonotonicNanos - initialMonotonicNanos
    let initialWallTimeNanos = self.initialWallTimeNanos
    return initialWallTimeNanos + elapsedNanos
  }

  public var now: Date {
    let seconds = TimeInterval(self.nanoTime) / 1_000_000_000
    return Date(timeIntervalSince1970: seconds)
  }
}
