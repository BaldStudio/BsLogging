//
//  UnusableLogHandler.swift
//  BsLogging
//
//  Created by Runze Chang on 2024/5/7.
//  Copyright © 2024 BaldStudio. All rights reserved.
//

public struct UnusableLogHandler: LogHandler {
    public init() {}

    @inlinable
    public func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             source: String,
             file: String,
             function: String,
             line: UInt) {}

    @inlinable
    public subscript(metadataKey _: String) -> Logger.Metadata.Value? {
        get { nil }
        set {}
    }

    public var metadata: Logger.Metadata {
        get { [:] }
        set {}
    }

    public var logLevel: Logger.Level {
        get {  .none }
        set {}
    }
}

