//
//  LogHandler.swift
//  BsLogging
//
//  Created by Runze Chang on 2024/5/7.
//  Copyright © 2024 BaldStudio. All rights reserved.
//

#if compiler(>=5.6)
@preconcurrency public protocol _SwiftLogSendableLogHandler: Sendable {}
#else
public protocol _SwiftLogSendableLogHandler {}
#endif

public protocol LogHandler: _SwiftLogSendableLogHandler {
    var metadataProvider: Logger.MetadataProvider? { get set }
    
    var metadata: Logger.Metadata { get set }
    
    var logLevel: Logger.Level { get set }
    
    subscript(metadataKey _: String) -> Logger.Metadata.Value? { get set }
    
    func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             source: String,
             file: String,
             function: String,
             line: UInt)
}

extension LogHandler {
    public var metadataProvider: Logger.MetadataProvider? {
        get { nil }
        set {
#if DEBUG
            if LoggingSystem.warnOnceLogHandlerNotSupportedMetadataProvider(Self.self) {
                log(level: .warn,
                    message: "Attempted to set metadataProvider on \(Self.self) that did not implement support for them. Please contact the log handler maintainer to implement metadata provider support.",
                    metadata: nil,
                    source: "BsLogging",
                    file: #file,
                    function: #function,
                    line: #line)
            }
#endif
        }
    }
}
