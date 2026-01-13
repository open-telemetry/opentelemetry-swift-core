/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

/// No-op implementations of BaggageManager.
public final class DefaultBaggageManagerProvider: BaggageManagerProvider, @unchecked Sendable {
  public static let instance = DefaultBaggageManagerProvider()

  public func create() -> BaggageManager {
    return DefaultBaggageManager.instance
  }
}
