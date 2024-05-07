//
//  Logging.swift
//  BsLogging
//
//  Created by crzorz on 2024/05/07.
//  Copyright © 2024 BaldStudio. All rights reserved.
//

#if compiler(>=5.7)
extension Logger.MetadataValue: Sendable {}
#elseif compiler(>=5.6)
extension Logger.MetadataValue: @unchecked Sendable {}
#endif

#if compiler(>=5.6)
extension Logger: Sendable {}
extension Logger.Level: Sendable {}
extension Logger.Message: Sendable {}
#endif

// MARK: -  Logger

public struct Logger {
    @usableFromInline
    var handler: LogHandler
    
    public let label: String
    
    public var metadataProvider: MetadataProvider? {
        handler.metadataProvider
    }
    
    @inlinable
    public var level: Logger.Level {
        get {
            handler.logLevel
        }
        set {
            handler.logLevel = newValue
        }
    }
    
    @inlinable
    public subscript(metadataKey key: String) -> Metadata.Value? {
        get {
            handler[metadataKey: key]
        }
        set {
            handler[metadataKey: key] = newValue
        }
    }
    
    init(label: String, _ handler: LogHandler) {
        self.label = label
        self.handler = handler
    }
    
    public init(label: String) {
        self.init(label: label, LoggingSystem.createLogHandler(label, LoggingSystem.metadataProvider))
    }
    
    public init(label: String, factory: (String) -> LogHandler) {
        self = Logger(label: label, factory(label))
    }
    
    public init(label: String, metadataProvider: MetadataProvider) {
        self = Logger(label: label, factory: { label in
            var handler = LoggingSystem.createLogHandler(label, metadataProvider)
            handler.metadataProvider = metadataProvider
            return handler
        })
    }
}

extension Logger {
#if compiler(>=5.3)
    @inlinable
    static func module(with file: String = #fileID) -> String {
        let utf8 = file.utf8
        if let slashIndex = utf8.firstIndex(of: UInt8(ascii: "/")) {
            return String(file[..<slashIndex])
        }
        return "n/a"
    }
#else
    @inlinable
    static func module(with file: String = #file) -> String {
        let utf8 = file.utf8
        return file.utf8.lastIndex(of: UInt8(ascii: "/")).flatMap { lastSlash -> Substring? in
            utf8[..<lastSlash].lastIndex(of: UInt8(ascii: "/")).map { secondLastSlash -> Substring in
                file[utf8.index(after: secondLastSlash) ..< lastSlash]
            }
        }.map { String($0) } ?? "n/a"
    }
#endif
}

// MARK: -  Log

extension Logger {
#if compiler(>=5.3)
    @inlinable
    func log(level: Logger.Level,
             _ message: @autoclosure () -> Logger.Message,
             metadata: @autoclosure () -> Logger.Metadata? = nil,
             source: @autoclosure () -> String? = nil,
             file: String = #fileID,
             function: String = #function,
             line: UInt = #line) {
        guard self.level <= level else { return }
        handler.log(level: level,
                    message: message(),
                    metadata: metadata(),
                    source: source() ?? Logger.module(with: file),
                    file: file,
                    function: function,
                    line: line)
    }
#else
    @inlinable
    func log(level: Logger.Level,
             _ message: @autoclosure () -> Logger.Message,
             metadata: @autoclosure () -> Logger.Metadata? = nil,
             source: @autoclosure () -> String? = nil,
             file: String = #file,
             function: String = #function,
             line: UInt = #line) {
        guard self.level <= level else { return }
        handler.log(level: level,
                    message: message(),
                    metadata: metadata(),
                    source: source() ?? Logger.module(with: file),
                    file: file,
                    function: function,
                    line: line)
    }
#endif
}

public extension Logger {
#if compiler(>=5.3)
    @inlinable
    func debug(_ message: @autoclosure () -> Logger.Message,
               metadata: @autoclosure () -> Logger.Metadata? = nil,
               source: @autoclosure () -> String? = nil,
               file: String = #fileID, 
               function: String = #function,
               line: UInt = #line) {
        log(level: .debug,
            message(),
            metadata: metadata(), 
            source: source(),
            file: file,
            function: function,
            line: line)
    }
#else
    @inlinable
    func debug(_ message: @autoclosure () -> Logger.Message,
               metadata: @autoclosure () -> Logger.Metadata? = nil,
               source: @autoclosure () -> String? = nil,
               file: String = #file, 
               function: String = #function,
               line: UInt = #line) {
        log(level: .debug,
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line)
    }
#endif
    
#if compiler(>=5.3)
    @inlinable
    func info(_ message: @autoclosure () -> Logger.Message,
              metadata: @autoclosure () -> Logger.Metadata? = nil,
              source: @autoclosure () -> String? = nil,
              file: String = #fileID, 
              function: String = #function,
              line: UInt = #line) {
        log(level: .info,
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line)
    }
#else
    @inlinable
    func info(_ message: @autoclosure () -> Logger.Message,
              metadata: @autoclosure () -> Logger.Metadata? = nil,
              source: @autoclosure () -> String? = nil,
              file: String = #file, 
              function: String = #function,
              line: UInt = #line) {
        log(level: .info,
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line)
    }
#endif
    
#if compiler(>=5.3)
    @inlinable
    func warn(_ message: @autoclosure () -> Logger.Message,
              metadata: @autoclosure () -> Logger.Metadata? = nil,
              source: @autoclosure () -> String? = nil,
              file: String = #fileID,
              function: String = #function,
              line: UInt = #line) {
        log(level: .warn,
            message(),
            metadata: metadata(), 
            source: source(),
            file: file,
            function: function,
            line: line)
    }
#else
    @inlinable
    func warn(_ message: @autoclosure () -> Logger.Message,
              metadata: @autoclosure () -> Logger.Metadata? = nil,
              source: @autoclosure () -> String? = nil,
              file: String = #file, 
              function: String = #function,
              line: UInt = #line) {
        log(level: .warn,
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line)
    }
#endif
    
#if compiler(>=5.3)
    @inlinable
    func error(_ message: @autoclosure () -> Logger.Message,
               metadata: @autoclosure () -> Logger.Metadata? = nil,
               source: @autoclosure () -> String? = nil,
               file: String = #fileID, 
               function: String = #function,
               line: UInt = #line) {
        log(level: .error,
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line)
    }
    
#else
    @inlinable
    func error(_ message: @autoclosure () -> Logger.Message,
               metadata: @autoclosure () -> Logger.Metadata? = nil,
               source: @autoclosure () -> String? = nil,
               file: String = #file, 
               function: String = #function,
               line: UInt = #line) {
        log(level: .error, 
            message(),
            metadata: metadata(), 
            source: source(),
            file: file,
            function: function,
            line: line)
    }
#endif
}

// MARK: -  Level

public extension Logger {
    enum Level: String, CaseIterable {
        case none
        case verbose
        case debug = "DEBUG"
        case info = "INFO"
        case warn = "WARN"
        case error = "ERROR"
    }
}

extension Logger.Level {
    var asInt: Int {
        switch self {
        case .none:
            return .max
        case .verbose:
            return 0
        case .debug:
            return 1
        case .info:
            return 2
        case .warn:
            return 3
        case .error:
            return 4
        }
    }
    
    var asEmoji: String {
        switch self {
        case .none:
            return ""
        case .verbose:
            return ""
        case .debug:
            return "⚪️"
        case .info:
            return "🟢"
        case .warn:
            return "⚠️"
        case .error:
            return "⁉️"
        }
    }
}

extension Logger.Level: Comparable {
    public static func < (lhs: Logger.Level, rhs: Logger.Level) -> Bool {
        return lhs.asInt < rhs.asInt
    }
}

// MARK: -  MetaData

extension Logger {
    public typealias Metadata = [String: MetadataValue]
    
    public enum MetadataValue {
        case string(String)
#if compiler(>=5.7)
        case stringConvertible(CustomStringConvertible & Sendable)
#else
        case stringConvertible(CustomStringConvertible)
#endif
        case dictionary(Metadata)
        case array([Metadata.Value])
    }
}

extension Logger.MetadataValue: Equatable {
    public static func == (lhs: Logger.Metadata.Value, rhs: Logger.Metadata.Value) -> Bool {
        switch (lhs, rhs) {
        case (.string(let lhs), .string(let rhs)):
            return lhs == rhs
        case (.stringConvertible(let lhs), .stringConvertible(let rhs)):
            return lhs.description == rhs.description
        case (.array(let lhs), .array(let rhs)):
            return lhs == rhs
        case (.dictionary(let lhs), .dictionary(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension Logger.MetadataValue: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension Logger.MetadataValue: ExpressibleByStringInterpolation {}

extension Logger.MetadataValue: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = Logger.Metadata.Value
    
    public init(dictionaryLiteral elements: (String, Logger.Metadata.Value)...) {
        self = .dictionary(.init(uniqueKeysWithValues: elements))
    }
}

extension Logger.MetadataValue: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Logger.Metadata.Value
    
    public init(arrayLiteral elements: Logger.Metadata.Value...) {
        self = .array(elements)
    }
}

extension Logger.MetadataValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .dictionary(let dict):
            return dict.mapValues { $0.description }.description
        case .array(let list):
            return list.map { $0.description }.description
        case .string(let str):
            return str
        case .stringConvertible(let repr):
            return repr.description
        }
    }
}


// MARK: -  Message

extension Logger {
    public struct Message: ExpressibleByStringLiteral, Equatable, CustomStringConvertible, ExpressibleByStringInterpolation {
        public typealias StringLiteralType = String
        
        private var value: String
        
        public init(stringLiteral value: String) {
            self.value = value
        }
        
        public var description: String {
            value
        }
    }
}
