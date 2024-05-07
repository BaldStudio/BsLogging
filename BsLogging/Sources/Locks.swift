//
//  Locks.swift
//  BsLogging
//
//  Created by Runze Chang on 2024/5/7.
//  Copyright © 2024 BaldStudio. All rights reserved.
//

import Darwin

final class Lock {
    private let mutex: UnsafeMutablePointer<pthread_mutex_t> = UnsafeMutablePointer.allocate(capacity: 1)
    
    init() {
        var attr = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_ERRORCHECK)
        let err = pthread_mutex_init(mutex, &attr)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
    }
    
    deinit {
        let err = pthread_mutex_destroy(mutex)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
        mutex.deallocate()
    }
}

extension Lock {
    func lock() {
        let err = pthread_mutex_lock(mutex)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
    }
    
    func unlock() {
        let err = pthread_mutex_unlock(mutex)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
    }
    
    @inlinable
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}

// MARK: - Read Write Lock

final class ReadWriteLock {
    private let mutex: UnsafeMutablePointer<pthread_rwlock_t> = UnsafeMutablePointer.allocate(capacity: 1)
    
    init() {
        let err = pthread_rwlock_init(mutex, nil)
        precondition(err == 0, "\(#function) failed in pthread_rwlock with error \(err)")
    }
    
    deinit {
        let err = pthread_rwlock_destroy(mutex)
        precondition(err == 0, "\(#function) failed in pthread_rwlock with error \(err)")
        mutex.deallocate()
    }
}

extension ReadWriteLock {
    func lockRead() {
        let err = pthread_rwlock_rdlock(mutex)
        precondition(err == 0, "\(#function) failed in pthread_rwlock with error \(err)")
    }
    
    func lockWrite() {
        let err = pthread_rwlock_wrlock(mutex)
        precondition(err == 0, "\(#function) failed in pthread_rwlock with error \(err)")
    }
    
    func unlock() {
        let err = pthread_rwlock_unlock(mutex)
        precondition(err == 0, "\(#function) failed in pthread_rwlock with error \(err)")
    }
    
    @inlinable
    func withReadLock<T>(_ body: () throws -> T) rethrows -> T {
        lockRead()
        defer { unlock() }
        return try body()
    }
    
    @inlinable
    func withWriteLock<T>(_ body: () throws -> T) rethrows -> T {
        lockWrite()
        defer { unlock() }
        return try body()
    }
}
