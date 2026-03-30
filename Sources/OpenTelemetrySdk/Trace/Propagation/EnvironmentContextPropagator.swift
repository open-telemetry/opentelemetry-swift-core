/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import OpenTelemetryApi


@available(*, deprecated, message: "Use EnvironmentMappingSetter or EnvironmentMappingGetter instead.")
public struct EnvironmentContextPropagator: TextMapPropagator {
  static let traceParent = "TRACEPARENT"
  static let traceState = "TRACESTATE"
  let w3cPropagator = W3CTraceContextPropagator()

  public let fields: Set<String> = [traceState, traceParent]

  public init() {}

  public func inject(spanContext: SpanContext, carrier: inout [String: String], setter: some Setter) {
    var auxCarrier = [String: String]()
    w3cPropagator.inject(spanContext: spanContext, carrier: &auxCarrier, setter: setter)
    carrier[EnvironmentContextPropagator.traceParent] = auxCarrier["traceparent"]
    carrier[EnvironmentContextPropagator.traceState] = auxCarrier["tracestate"]
  }

  public func extract(carrier: [String: String], getter: some Getter) -> SpanContext? {
    var auxCarrier = [String: String]()
    auxCarrier["traceparent"] = carrier[EnvironmentContextPropagator.traceParent]
    auxCarrier["tracestate"] = carrier[EnvironmentContextPropagator.traceState]
    return w3cPropagator.extract(carrier: auxCarrier, getter: getter)
  }
}

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
