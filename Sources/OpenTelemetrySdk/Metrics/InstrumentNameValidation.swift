//
// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0
//

import OpenTelemetryApi

/// Validates instrument names against the OpenTelemetry metrics specification.
///
/// The specification leaves this validation to implementations of the API, such as the SDK:
/// https://opentelemetry.io/docs/specs/otel/metrics/api/#instrument-name-syntax
enum InstrumentNameValidation {
  /// The maximum number of characters allowed in an instrument name.
  static let maximumLength = 255

  /// Returns whether `name` conforms to the instrument name syntax.
  ///
  /// A conforming name is not empty, is at most ``maximumLength`` characters long, begins with an
  /// ASCII alphabetic character, and otherwise contains only ASCII alphanumeric characters,
  /// `_`, `.`, `-`, or `/`.
  static func isValid(_ name: String) -> Bool {
    guard !name.isEmpty, name.count <= maximumLength else { return false }

    var isFirstCharacter = true
    for scalar in name.unicodeScalars {
      if isFirstCharacter {
        guard isAlphabetic(scalar) else { return false }
        isFirstCharacter = false
      } else if !isAlphabetic(scalar),
                !isDigit(scalar),
                scalar != "_", scalar != ".", scalar != "-", scalar != "/" {
        return false
      }
    }
    return true
  }

  /// Emits a message through the feedback handler when `name` does not conform to the specification.
  static func warnIfInvalid(_ name: String) {
    guard !isValid(name) else { return }
    OpenTelemetry.instance.feedbackHandler?(
      "Instrument name \"\(name)\" does not conform to the OpenTelemetry specification. Names must be non-empty, at most \(maximumLength) characters, start with an alphabetic character, and otherwise contain only alphanumeric characters, '_', '.', '-', or '/'. The instrument was still created, but the resulting metric may be rejected by the backend. See https://opentelemetry.io/docs/specs/otel/metrics/api/#instrument-name-syntax"
    )
  }

  private static func isAlphabetic(_ scalar: Unicode.Scalar) -> Bool {
    (scalar >= "a" && scalar <= "z") || (scalar >= "A" && scalar <= "Z")
  }

  private static func isDigit(_ scalar: Unicode.Scalar) -> Bool {
    scalar >= "0" && scalar <= "9"
  }
}
