/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

// ===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Metrics API open source project
//
// Copyright (c) 2018-2019 Apple Inc. and the Swift Metrics API project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Metrics API project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

// ===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  import Darwin
#elseif canImport(Glibc)
  import Glibc
#elseif canImport(Musl)
  import Musl
#else
  #error("Unsupported platform")
#endif

/// A pthread-based read-write lock.
///
/// Allows multiple concurrent readers or a single exclusive writer.
/// The SDK vendors its own copy of this class (`OpenTelemetrySdk/Internal/Locks.swift`):
/// sharing one implementation would require `package` visibility, which CocoaPods
/// builds only support via fragile cross-pod `-package-name` flags.
final class ReadWriteLock: @unchecked Sendable {
  private let rwlock: UnsafeMutablePointer<pthread_rwlock_t> = UnsafeMutablePointer.allocate(capacity: 1)

  init() {
    let err = pthread_rwlock_init(rwlock, nil)
    precondition(err == 0, "pthread_rwlock_init failed with error \(err)")
  }

  deinit {
    let err = pthread_rwlock_destroy(self.rwlock)
    precondition(err == 0, "pthread_rwlock_destroy failed with error \(err)")
    self.rwlock.deallocate()
  }

  /// Acquire a reader lock.
  ///
  /// Whenever possible, consider using `withReaderLock` instead of this
  /// method and `unlock`, to simplify lock handling.
  func lockRead() {
    let err = pthread_rwlock_rdlock(rwlock)
    precondition(err == 0, "pthread_rwlock_rdlock failed with error \(err)")
  }

  /// Acquire a writer lock.
  ///
  /// Whenever possible, consider using `withWriterLock` instead of this
  /// method and `unlock`, to simplify lock handling.
  func lockWrite() {
    let err = pthread_rwlock_wrlock(rwlock)
    precondition(err == 0, "pthread_rwlock_wrlock failed with error \(err)")
  }

  /// Release the lock.
  func unlock() {
    let err = pthread_rwlock_unlock(rwlock)
    precondition(err == 0, "pthread_rwlock_unlock failed with error \(err)")
  }

  /// Acquire the reader lock for the duration of the given block.
  ///
  /// This convenience method should be preferred to `lockRead` and `unlock`
  /// in most situations, as it ensures that the lock will be released
  /// regardless of how `body` exits.
  func withReaderLock<T>(_ body: () throws -> T) rethrows -> T {
    lockRead()
    defer {
      self.unlock()
    }
    return try body()
  }

  /// Acquire the writer lock for the duration of the given block.
  ///
  /// This convenience method should be preferred to `lockWrite` and `unlock`
  /// in most situations, as it ensures that the lock will be released
  /// regardless of how `body` exits.
  func withWriterLock<T>(_ body: () throws -> T) rethrows -> T {
    lockWrite()
    defer {
      self.unlock()
    }
    return try body()
  }
}
