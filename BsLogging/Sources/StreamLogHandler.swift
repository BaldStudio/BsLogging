//
//  StreamLogHandler.swift
//  BsLogging
//
//  Created by Runze Chang on 2024/5/7.
//  Copyright © 2024 BaldStudio. All rights reserved.
//

import Darwin

// MARK: -  StreamLogHandler

public struct StreamLogHandler: LogHandler {
#if compiler(>=5.6)
    typealias _SendableTextOutputStream = TextOutputStream & Sendable
#else
    typealias _SendableTextOutputStream = TextOutputStream
#endif
    
    public static func standardOutput(label: String) -> StreamLogHandler {
        StreamLogHandler(label: label,
                         stream: StdioOutputStream.stdout,
                         metadataProvider: LoggingSystem.metadataProvider)
    }
    
    public static func standardOutput(label: String,
                                      metadataProvider: Logger.MetadataProvider?) -> StreamLogHandler {
        StreamLogHandler(label: label,
                         stream: StdioOutputStream.stdout,
                         metadataProvider: metadataProvider)
    }
    
    public static func standardError(label: String) -> StreamLogHandler {
        StreamLogHandler(label: label,
                         stream: StdioOutputStream.stderr,
                         metadataProvider: LoggingSystem.metadataProvider)
    }
    
    public static func standardError(label: String,
                                     metadataProvider: Logger.MetadataProvider?) -> StreamLogHandler {
        StreamLogHandler(label: label,
                         stream: StdioOutputStream.stderr,
                         metadataProvider: metadataProvider)
    }
    
    private let stream: _SendableTextOutputStream
    private let label: String
    
    public var logLevel: Logger.Level = .verbose
    
    public var metadataProvider: Logger.MetadataProvider?
    
    private var prettyMetadata: String?
    public var metadata = Logger.Metadata() {
        didSet {
            prettyMetadata = prettify(metadata)
        }
    }
    
    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            metadata[key]
        }
        set {
            metadata[key] = newValue
        }
    }
    
    init(label: String, stream: _SendableTextOutputStream, metadataProvider: Logger.MetadataProvider? = nil) {
        self.label = label
        self.stream = stream
        self.metadataProvider = metadataProvider
    }
    
    public func log(level: Logger.Level,
                    message: Logger.Message,
                    metadata explicitMetadata: Logger.Metadata?,
                    source: String,
                    file: String,
                    function: String,
                    line: UInt) {
        let effectiveMetadata = StreamLogHandler.prepareMetadata(base: self.metadata,
                                                                 provider: self.metadataProvider,
                                                                 explicit: explicitMetadata)
        let prettyMetadata: String?
        if let effectiveMetadata {
            prettyMetadata = self.prettify(effectiveMetadata)
        } else {
            prettyMetadata = self.prettyMetadata
        }
        
        let label = self.label.isEmpty ? source : "\(self.label)"
        let lv = level.rawValue
        let emoji = level.asEmoji
        let pretty = prettyMetadata.map { " \($0)" } ?? ""
        
        var stream = self.stream
        stream.write("\(timestamp) [\(label)] <\(lv)> \(emoji)\(pretty) \(message)\n")
    }
    
    static func prepareMetadata(base: Logger.Metadata,
                                provider: Logger.MetadataProvider?,
                                explicit: Logger.Metadata?) -> Logger.Metadata? {
        var metadata = base
        
        let providedMetadata = provider?.metadata ?? [:]
        let explicitMetadata = explicit ?? [:]
        
        guard !providedMetadata.isEmpty || !explicitMetadata.isEmpty else {
            return nil
        }
        
        if !providedMetadata.isEmpty {
            metadata.merge(providedMetadata, uniquingKeysWith: { _, new in new })
        }
        
        if !explicitMetadata.isEmpty {
            metadata.merge(explicitMetadata, uniquingKeysWith: { _, new in new })
        }
        
        return metadata
    }
    
    private func prettify(_ metadata: Logger.Metadata) -> String? {
        if metadata.isEmpty {
            return nil
        }
        return metadata.lazy.sorted(by: { $0.key < $1.key }).map { "\($0)=\($1)" }.joined(separator: " ")
    }
    
    private var timestamp: String {
        var buffer = [Int8](repeating: 0, count: 255)
        var tv = timeval()
        gettimeofday(&tv, nil)
        guard let localTime = localtime(&tv.tv_sec) else {
            return "<unknown>"
        }
        strftime(&buffer, buffer.count, "%F %T", localTime)
        let now = buffer.withUnsafeBufferPointer {
            $0.withMemoryRebound(to: CChar.self) {
                String(cString: $0.baseAddress!)
            }
        }
        return "\(now).\(tv.tv_usec)"
    }
}

// MARK: -  StdioOutputStream

typealias CFilePointer = UnsafeMutablePointer<FILE>

private let systemStderr = Darwin.stderr
private let systemStdout = Darwin.stdout

struct StdioOutputStream: TextOutputStream {
    enum FlushMode {
        case undefined
        case always
    }
    
    let file: CFilePointer
    let flushMode: FlushMode
    
    static let stderr = StdioOutputStream(file: systemStderr, flushMode: .always)
    static let stdout = StdioOutputStream(file: systemStdout, flushMode: .always)
    
    func write(_ string: String) {
        string.asContiguousUTF8.withContiguousStorageIfAvailable { bytes in
            flockfile(self.file)
            defer {
                funlockfile(self.file)
            }
            _ = fwrite(bytes.baseAddress!, 1, bytes.count, self.file)
            if case .always = self.flushMode {
                self.flush()
            }
        }!
    }
    
    func flush() {
        _ = fflush(file)
    }
}

private extension String {
    var asContiguousUTF8: String.UTF8View {
        var contiguousString = self
#if compiler(>=5.1)
        contiguousString.makeContiguousUTF8()
#else
        contiguousString = self + ""
#endif
        return contiguousString.utf8
    }
}
