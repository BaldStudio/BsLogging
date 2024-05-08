//
//  LoggingSystem.swift
//  BsLogging
//
//  Created by Runze Chang on 2024/5/7.
//  Copyright © 2024 BaldStudio. All rights reserved.
//

// MARK: -  LoggingSystem

public enum LoggingSystem {
    static let logHandlerFactory = LogHandlerFactory { label, _ in
        StreamLogHandler.standardOutput(label: label)
    }
    static let metadataProviderFactory = MetadataProviderFactory(nil)
    
#if DEBUG
    private static var warnOnceBox: WarnOnceBox = WarnOnceBox()
#endif
    
    public static var metadataProvider: Logger.MetadataProvider? {
        metadataProviderFactory.make()
    }
    
    public static func bootstrap(_ factory: @escaping (String) -> LogHandler) {
        bootstrap(validate: true, factory)
    }
    
    // easy to test
    static func bootstrap(validate: Bool, _ factory: @escaping (String) -> LogHandler) {
        logHandlerFactory.changeUnderlying(validate: false) { label, _ in
            factory(label)
        }
    }
    
    public static func bootstrap(metadataProvider: Logger.MetadataProvider?,
                                 _ factory: @escaping (String, Logger.MetadataProvider?) -> LogHandler) {
        bootstrap(validate: true, metadataProvider: metadataProvider, factory)
    }
    
    // easy to test
    static func bootstrap(validate: Bool,
                          metadataProvider: Logger.MetadataProvider?,
                          _ factory: @escaping (String, Logger.MetadataProvider?) -> LogHandler) {
        metadataProviderFactory.changeUnderlying(validate: validate, metadataProvider)
        logHandlerFactory.changeUnderlying(validate: validate, factory)
    }
}

extension LoggingSystem {
    static func createLogHandler(_ label: String, _ provider: Logger.MetadataProvider?) -> LogHandler {
        logHandlerFactory.make(label, metadataProvider)
    }
    
#if DEBUG
    static func warnOnceLogHandlerNotSupportedMetadataProvider<Handler: LogHandler>(_ type: Handler.Type) -> Bool {
        warnOnceBox.warnOnceLogHandlerNotSupportedMetadataProvider(type: type)
    }
#endif
}

// MARK: -  Factory

extension LoggingSystem {
    final class LogHandlerFactory {
        private let lock = ReadWriteLock()
        private var initialized = false
        private var underlying: (String, Logger.MetadataProvider?) -> LogHandler
        
        init(_ underlying: @escaping (String, Logger.MetadataProvider?) -> LogHandler) {
            self.underlying = underlying
        }
        
        func changeUnderlying(validate: Bool = false,
                              _ underlying: @escaping (String, Logger.MetadataProvider?) -> LogHandler) {
            lock.withWriteLock {
                precondition(!validate || !self.initialized, "logging system can only be initialized once per process.")
                self.underlying = underlying
                self.initialized = true
            }
        }
        
        func make(_ label: String, _ provider: Logger.MetadataProvider?) -> LogHandler {
            lock.withReadLock {
                self.underlying(label, provider)
            }
        }
    }
    
    final class MetadataProviderFactory {
        private let lock = ReadWriteLock()
        
        private var underlying: Logger.MetadataProvider?
        private var initialized = false
        
        init(_ underlying: Logger.MetadataProvider?) {
            self.underlying = underlying
        }
        
        func changeUnderlying(validate: Bool = false, _ underlying: Logger.MetadataProvider?) {
            self.lock.withWriteLock {
                precondition(!validate || !self.initialized, "logging system can only be initialized once per process.")
                self.underlying = underlying
                self.initialized = true
            }
        }
        
        func make() -> Logger.MetadataProvider? {
            lock.withReadLock {
                self.underlying
            }
        }
    }
    
#if DEBUG
    final class WarnOnceBox {
        private let lock: Lock = Lock()
        private var warnOnceLogHandlerNotSupportedMetadataProviderPerType: [ObjectIdentifier: Bool] = [:]
        
        func warnOnceLogHandlerNotSupportedMetadataProvider<Handler: LogHandler>(type: Handler.Type) -> Bool {
            lock.withLock {
                let id = ObjectIdentifier(type)
                if self.warnOnceLogHandlerNotSupportedMetadataProviderPerType[id] ?? false {
                    return false
                }
                self.warnOnceLogHandlerNotSupportedMetadataProviderPerType[id] = true
                return true
            }
        }
    }
#endif
}
