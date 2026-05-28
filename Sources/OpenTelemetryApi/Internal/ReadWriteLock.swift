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

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  import Darwin
#elseif canImport(Glibc)
  import Glibc
#elseif canImport(Musl)
  import Musl
#else
  #error("Unsupported platform")
#endif

/// A pthread-based read-write lock for the OpenTelemetryApi module.
///
/// Allows multiple concurrent readers or a single exclusive writer.
/// Used to synchronize access to the OpenTelemetry singleton state.
final class ApiReadWriteLock: @unchecked Sendable {
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

  @inlinable
  func withReaderLock<T>(_ body: () throws -> T) rethrows -> T {
    let err = pthread_rwlock_rdlock(rwlock)
    precondition(err == 0, "pthread_rwlock_rdlock failed with error \(err)")
    defer {
      let unlockErr = pthread_rwlock_unlock(self.rwlock)
      precondition(unlockErr == 0, "pthread_rwlock_unlock failed with error \(unlockErr)")
    }
    return try body()
  }

  @inlinable
  func withWriterLock<T>(_ body: () throws -> T) rethrows -> T {
    let err = pthread_rwlock_wrlock(rwlock)
    precondition(err == 0, "pthread_rwlock_wrlock failed with error \(err)")
    defer {
      let unlockErr = pthread_rwlock_unlock(self.rwlock)
      precondition(unlockErr == 0, "pthread_rwlock_unlock failed with error \(unlockErr)")
    }
    return try body()
  }
}
