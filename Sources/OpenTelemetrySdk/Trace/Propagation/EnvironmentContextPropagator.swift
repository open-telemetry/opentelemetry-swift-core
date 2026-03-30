/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import OpenTelemetryApi

/**
 * EnvironmentMappingSetter adapts a `Setter` to normalize propagation keys to environment variable format.
 *
 * Normalization rules per OpenTelemetry specification:
 * - Converts keys to uppercase (e.g., "traceparent" → "TRACEPARENT")
 * - Replaces all non-alphanumeric characters (except underscore) with underscores
 *   (e.g., "x-b3-traceid" → "X_B3_TRACEID")
 *
 * Usage:
 * ```swift
 * let innerSetter = MyCustomSetter()
 * let envSetter = EnvironmentMappingSetter(innerSetter: innerSetter)
 * w3cPropagator.inject(spanContext: context, carrier: &carrier, setter: envSetter)
 * ```
 *
 * See: https://opentelemetry.io/docs/specs/otel/context/env-carriers/
 */
public struct EnvironmentMappingSetter: Setter {
  let innerSetter: any Setter

  public init(innerSetter: any Setter) {
    self.innerSetter = innerSetter
  }

  public func set(carrier: inout [String: String], key: String, value: String) {
    let mappedKey = normalizeKeyForEnvironment(key)
    innerSetter.set(carrier: &carrier, key: mappedKey, value: value)
  }
}

/**
 * EnvironmentMappingGetter adapts a `Getter` to normalize propagation keys to environment variable format.
 *
 * Normalization rules per OpenTelemetry specification:
 * - Converts keys to uppercase (e.g., "traceparent" → "TRACEPARENT")
 * - Replaces all non-alphanumeric characters (except underscore) with underscores
 *   (e.g., "x-b3-traceid" → "X_B3_TRACEID")
 *
 * Usage:
 * ```swift
 * let innerGetter = EnvironmentVariableGetter()
 * let envGetter = EnvironmentMappingGetter(innerGetter: innerGetter)
 * let spanContext = w3cPropagator.extract(carrier: ProcessInfo.processInfo.environment, getter: envGetter)
 * ```
 *
 * See: https://opentelemetry.io/docs/specs/otel/context/env-carriers/
 */
public struct EnvironmentMappingGetter: Getter {
  let innerGetter: any Getter

  public init(innerGetter: any Getter) {
    self.innerGetter = innerGetter
  }

  public func get(carrier: [String: String], key: String) -> [String]? {
    let mappedKey = normalizeKeyForEnvironment(key)
    return innerGetter.get(carrier: carrier, key: mappedKey)
  }
}

/// Normalizes a key for environment variable format:
/// - Converts to uppercase
/// - Replaces every non-alphanumeric and non-underscore character with an underscore
private func normalizeKeyForEnvironment(_ key: String) -> String {
  let normalized = key.uppercased()
  return normalized.map { char -> String in
    if char.isLetter || char.isNumber || char == "_" {
      return String(char)
    } else {
      return "_"
    }
  }.joined()
}
