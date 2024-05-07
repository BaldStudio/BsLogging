//
//  LoggingTest.swift
//  BsLoggingTests
//
//  Created by crzorz on 2024/05/07.
//  Copyright © 2024 BaldStudio. All rights reserved.
//

import XCTest
@testable import BsLogging

class LoggingTest: XCTestCase {
    func testAutoclosure() {
        let logging = TestLogging()
        LoggingSystem.bootstrap(validate: false, logging.make)

        var logger = Logger(label: "test")
        logger.level = .info
        logger.log(level: .debug, {
            XCTFail("debug should not be called")
            return "debug"
        }())
        logger.debug({
            XCTFail("debug should not be called")
            return "debug"
        }())
        logger.info({
            "info"
        }())
        logger.warn({
            "warning"
        }())
        logger.error({
            "error"
        }())
        XCTAssertEqual(3, logging.history.entries.count, "expected number of entries to match")
        logging.history.assertNotExist(level: .debug, message: "trace")
        logging.history.assertNotExist(level: .debug, message: "debug")
        logging.history.assertExist(level: .info, message: "info")
        logging.history.assertExist(level: .warn, message: "warning")
        logging.history.assertExist(level: .error, message: "error")
    }
    
    enum TestError: Error {
        case boom
    }

    func testDictionaryMetadata() {
        let testLogging = TestLogging()
        LoggingSystem.bootstrap(validate: false, testLogging.make)

        var logger = Logger(label: "\(#function)")
        logger[metadataKey: "foo"] = ["bar": "buz"]
        logger[metadataKey: "empty-dict"] = [:]
        logger[metadataKey: "nested-dict"] = ["l1key": ["l2key": ["l3key": "l3value"]]]
        logger.info("hello world!")
        testLogging.history.assertExist(level: .info,
                                        message: "hello world!",
                                        metadata: ["foo": ["bar": "buz"],
                                                   "empty-dict": [:],
                                                   "nested-dict": ["l1key": ["l2key": ["l3key": "l3value"]]]])
    }
    
    func testListMetadata() {
        let testLogging = TestLogging()
        LoggingSystem.bootstrap(validate: false, testLogging.make)

        var logger = Logger(label: "\(#function)")
        logger[metadataKey: "foo"] = ["bar", "buz"]
        logger[metadataKey: "empty-list"] = []
        logger[metadataKey: "nested-list"] = ["l1str", ["l2str1", "l2str2"]]
        logger.info("hello world!")
        testLogging.history.assertExist(level: .info,
                                        message: "hello world!",
                                        metadata: ["foo": ["bar", "buz"],
                                                   "empty-list": [],
                                                   "nested-list": ["l1str", ["l2str1", "l2str2"]]])
    }
    
    internal final class LazyMetadataBox: CustomStringConvertible {
        private var makeValue: (() -> String)?
        private var _value: String?

        public init(_ makeValue: @escaping () -> String) {
            self.makeValue = makeValue
        }

        /// This allows caching a value in case it is accessed via an by name subscript,
        // rather than as part of rendering all metadata that a LoggingContext was carrying
        public var value: String {
            if let f = self.makeValue {
                self._value = f()
                self.makeValue = nil
            }

            assert(self._value != nil, "_value MUST NOT be nil once `lazyValue` has run.")
            return self._value!
        }

        public var description: String {
            return "\(self.value)"
        }
    }

    private func dontEvaluateThisString(file: StaticString = #file, line: UInt = #line) -> Logger.Message {
        XCTFail("should not have been evaluated", file: file, line: line)
        return "should not have been evaluated"
    }

    func testAutoClosuresAreNotForcedUnlessNeeded() {
        let testLogging = TestLogging()
        LoggingSystem.bootstrap(validate: false, testLogging.make)

        var logger = Logger(label: "\(#function)")
        logger.level = .error

        logger.debug(self.dontEvaluateThisString(), metadata: ["foo": "\(self.dontEvaluateThisString())"])
        logger.debug(self.dontEvaluateThisString())
        logger.info(self.dontEvaluateThisString())
        logger.warn(self.dontEvaluateThisString())
        logger.log(level: .warn, self.dontEvaluateThisString())
    }

    func testLocalMetadata() {
        let testLogging = TestLogging()
        LoggingSystem.bootstrap(validate: false, testLogging.make)

        var logger = Logger(label: "\(#function)")
        logger.info("hello world!", metadata: ["foo": "bar"])
        logger[metadataKey: "bar"] = "baz"
        logger[metadataKey: "baz"] = "qux"
        logger.warn("hello world!")
        logger.error("hello world!", metadata: ["baz": "quc"])
        testLogging.history.assertExist(level: .info, message: "hello world!", metadata: ["foo": "bar"])
        testLogging.history.assertExist(level: .warn, message: "hello world!", metadata: ["bar": "baz", "baz": "qux"])
        testLogging.history.assertExist(level: .error, message: "hello world!", metadata: ["bar": "baz", "baz": "quc"])
    }

    func testCustomFactory() {
        struct CustomHandler: LogHandler {
            func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {}

            subscript(metadataKey _: String) -> Logger.Metadata.Value? {
                get { return nil }
                set {}
            }

            var metadata: Logger.Metadata {
                get { return Logger.Metadata() }
                set {}
            }

            var logLevel: Logger.Level {
                get { return .info }
                set {}
            }
        }

        let logger1 = Logger(label: "foo")
        XCTAssertFalse(logger1.handler is CustomHandler, "expected non-custom log handler")
        let logger2 = Logger(label: "foo", factory: { _ in CustomHandler() })
        XCTAssertTrue(logger2.handler is CustomHandler, "expected custom log handler")
    }

    func testAllLogLevelsExceptCriticalCanBeBlocked() {
        let testLogging = TestLogging()
        LoggingSystem.bootstrap(validate: false, testLogging.make)

        var logger = Logger(label: "\(#function)")
        logger.level = .error

        logger.debug("no")
        logger.info("no")
        logger.warn("no")
        logger.error("no")

        testLogging.history.assertNotExist(level: .debug, message: "no")
        testLogging.history.assertNotExist(level: .info, message: "no")
        testLogging.history.assertNotExist(level: .warn, message: "no")
        testLogging.history.assertNotExist(level: .error, message: "no")
    }

    func testAllLogLevelsWork() {
        let testLogging = TestLogging()
        LoggingSystem.bootstrap(validate: false, testLogging.make)

        var logger = Logger(label: "\(#function)")
        logger.level = .verbose

        logger.debug("yes: debug")
        logger.info("yes: info")
        logger.warn("yes: warn")
        logger.error("yes: error")

        testLogging.history.assertExist(level: .debug, message: "yes: debug")
        testLogging.history.assertExist(level: .info, message: "yes: info")
        testLogging.history.assertExist(level: .warn, message: "yes: warn")
        testLogging.history.assertExist(level: .error, message: "yes: error")
    }

    func testAllLogLevelByFunctionRefWithSource() {
        let testLogging = TestLogging()
        LoggingSystem.bootstrap(validate: false, testLogging.make)

        var logger = Logger(label: "\(#function)")
        logger.level = .verbose

        let debug = logger.debug(_:metadata:source:file:function:line:)
        let info = logger.info(_:metadata:source:file:function:line:)
        let warn = logger.warn(_:metadata:source:file:function:line:)
        let error = logger.error(_:metadata:source:file:function:line:)

        debug("yes: debug", [:], "foo", #file, #function, #line)
        info("yes: info", [:], "foo", #file, #function, #line)
        warn("yes: warn", [:], "foo", #file, #function, #line)
        error("yes: error", [:], "foo", #file, #function, #line)

        testLogging.history.assertExist(level: .debug, message: "yes: debug", source: "foo")
        testLogging.history.assertExist(level: .info, message: "yes: info", source: "foo")
        testLogging.history.assertExist(level: .warn, message: "yes: warn", source: "foo")
        testLogging.history.assertExist(level: .error, message: "yes: error", source: "foo")
    }

    func testLogsEmittedFromSubdirectoryGetCorrectModuleInNewerSwifts() {
        let testLogging = TestLogging()
        LoggingSystem.bootstrap(validate: false, testLogging.make)

        var logger = Logger(label: "\(#function)")
        logger.level = .verbose

        emitLogMessage("hello", to: logger)

        #if compiler(>=5.3)
        let moduleName = "BsLoggingTests" // the actual name
        #else
        let moduleName = "SubDirectoryOfLoggingTests" // the last path component of `#file` showing the failure mode
        #endif

        testLogging.history.assertExist(level: .debug, message: "hello", source: moduleName)
        testLogging.history.assertExist(level: .info, message: "hello", source: moduleName)
        testLogging.history.assertExist(level: .warn, message: "hello", source: moduleName)
        testLogging.history.assertExist(level: .error, message: "hello", source: moduleName)
    }

    func testLogMessageWithStringInterpolation() {
        let testLogging = TestLogging()
        LoggingSystem.bootstrap(validate: false, testLogging.make)

        var logger = Logger(label: "\(#function)")
        logger.level = .debug

        let someInt = Int.random(in: 23 ..< 42)
        logger.debug("My favourite number is \(someInt) and not \(someInt - 1)")
        testLogging.history.assertExist(level: .debug,
                                        message: "My favourite number is \(someInt) and not \(someInt - 1)" as String)
    }

    func testLoggingAString() {
        let testLogging = TestLogging()
        LoggingSystem.bootstrap(validate: false, testLogging.make)

        var logger = Logger(label: "\(#function)")
        logger.level = .debug

        let anActualString: String = "hello world!"
        logger.debug("\(anActualString)")
        testLogging.history.assertExist(level: .debug, message: "hello world!")
    }

    func testLoggerWithoutFactoryOverrideDefaultsToUsingLoggingSystemMetadataProvider() {
        let logging = TestLogging()
        LoggingSystem.bootstrap(validate: false, metadataProvider: .init { ["provider": "42"] }) { label, metadataProvider in
            logging.makeWithMetadataProvider(label: label, metadataProvider: metadataProvider)
        }

        let logger = Logger(label: #function)

        logger.log(level: .info, "test", metadata: ["one-off": "42"])

        logging.history.assertExist(level: .info,
                                    message: "test",
                                    metadata: ["provider": "42", "one-off": "42"])
    }

    func testLoggerWithPredefinedLibraryMetadataProvider() {
        let logging = TestLogging()
        LoggingSystem.bootstrap(validate: false, 
            metadataProvider: .exampleMetadataProvider,
            logging.makeWithMetadataProvider
        )

        let logger = Logger(label: #function)

        logger.log(level: .info, "test", metadata: ["one-off": "42"])

        logging.history.assertExist(level: .info,
                                    message: "test",
                                    metadata: ["example": "example-value", "one-off": "42"])
    }

    func testLoggerWithFactoryOverrideDefaultsToUsingLoggingSystemMetadataProvider() {
        let logging = TestLogging()
        LoggingSystem.bootstrap(validate: false,
                                metadataProvider: .init { ["provider": "42"] },
                                logging.makeWithMetadataProvider)

        let logger = Logger(label: #function, factory: { label in
            logging.makeWithMetadataProvider(label: label, metadataProvider: LoggingSystem.metadataProvider)
        })

        logger.log(level: .info, "test", metadata: ["one-off": "42"])

        logging.history.assertExist(level: .info,
                                    message: "test",
                                    metadata: ["provider": "42", "one-off": "42"])
    }

    func testLoggerWithGlobalOverride() {
        struct LogHandlerWithGlobalLogLevelOverride: LogHandler {
            // the static properties hold the globally overridden log level (if overridden)
            private static let overrideLock = Lock()
            private static var overrideLogLevel: Logger.Level?

            private let recorder: Recorder
            // this holds the log level if not overridden
            private var _logLevel: Logger.Level = .info

            // metadata storage
            var metadata: Logger.Metadata = [:]

            init(recorder: Recorder) {
                self.recorder = recorder
            }

            var logLevel: Logger.Level {
                get {
                    return LogHandlerWithGlobalLogLevelOverride.overrideLock.withLock {
                        LogHandlerWithGlobalLogLevelOverride.overrideLogLevel
                    } ?? self._logLevel
                }
                set {
                    self._logLevel = newValue
                }
            }

            func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?,
                     source: String, file: String, function: String, line: UInt) {
                self.recorder.record(level: level, metadata: metadata, message: message, source: source)
            }

            subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
                get {
                    return self.metadata[metadataKey]
                }
                set(newValue) {
                    self.metadata[metadataKey] = newValue
                }
            }

            // this is the function to globally override the log level, it is not part of the `LogHandler` protocol
            static func overrideGlobalLogLevel(_ logLevel: Logger.Level) {
                LogHandlerWithGlobalLogLevelOverride.overrideLock.withLock {
                    LogHandlerWithGlobalLogLevelOverride.overrideLogLevel = logLevel
                }
            }
        }

        let logRecorder = Recorder()
        LoggingSystem.bootstrap(validate: false) { _ in
            LogHandlerWithGlobalLogLevelOverride(recorder: logRecorder)
        }

        var logger1 = Logger(label: "logger-\(#file):\(#line)")
        var logger2 = logger1
        logger1.level = .warn
        logger1[metadataKey: "only-on"] = "first"
        logger2.level = .error
        logger2[metadataKey: "only-on"] = "second"
        XCTAssertEqual(.error, logger2.level)
        XCTAssertEqual(.warn, logger1.level)
        XCTAssertEqual("first", logger1[metadataKey: "only-on"])
        XCTAssertEqual("second", logger2[metadataKey: "only-on"])

        logger1.info("logger1, before")
        logger2.info("logger2, before")

        LogHandlerWithGlobalLogLevelOverride.overrideGlobalLogLevel(.debug)

        logger1.info("logger1, after")
        logger2.info("logger2, after")

        logRecorder.assertNotExist(level: .info, message: "logger1, before")
        logRecorder.assertNotExist(level: .info, message: "logger2, before")
        logRecorder.assertExist(level: .info, message: "logger1, after")
        logRecorder.assertExist(level: .info, message: "logger2, after")
    }

    func testLogLevelCases() {
        let levels = Logger.Level.allCases
        XCTAssertEqual(6, levels.count)
    }

    func testLogLevelOrdering() {
        XCTAssertLessThan(Logger.Level.verbose, Logger.Level.debug)
        XCTAssertLessThan(Logger.Level.verbose, Logger.Level.info)
        XCTAssertLessThan(Logger.Level.verbose, Logger.Level.warn)
        XCTAssertLessThan(Logger.Level.verbose, Logger.Level.error)
        XCTAssertLessThan(Logger.Level.debug, Logger.Level.info)
        XCTAssertLessThan(Logger.Level.debug, Logger.Level.warn)
        XCTAssertLessThan(Logger.Level.debug, Logger.Level.error)
        XCTAssertLessThan(Logger.Level.info, Logger.Level.warn)
        XCTAssertLessThan(Logger.Level.info, Logger.Level.error)
        XCTAssertLessThan(Logger.Level.warn, Logger.Level.error)
    }

    final class InterceptStream: TextOutputStream {
        var interceptedText: String?
        var strings = [String]()

        func write(_ string: String) {
            self.strings.append(string)
            self.interceptedText = (self.interceptedText ?? "") + string
        }
    }

    func testStreamLogHandlerWritesToAStream() {
        let interceptStream = InterceptStream()
        LoggingSystem.bootstrap(validate: false) { _ in
            StreamLogHandler(label: "test", stream: interceptStream)
        }
        let log = Logger(label: "test")

        let testString = "my message is better than yours"
        log.error("\(testString)")

        let messageSucceeded = interceptStream.interceptedText?.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix(testString)

        XCTAssertTrue(messageSucceeded ?? false)
        XCTAssertEqual(interceptStream.strings.count, 1)
    }

    func testStreamLogHandlerOutputFormatWithOrderedMetadata() {
        let interceptStream = InterceptStream()
        let label = "testLabel"
        LoggingSystem.bootstrap(validate: false) { label in
            StreamLogHandler(label: label, stream: interceptStream)
        }
        let log = Logger(label: label)

        let testString = "my message is better than yours"
        log.error("\(testString)", metadata: ["a": "a0", "b": "b0"])
        log.error("\(testString)", metadata: ["b": "b1", "a": "a1"])

        XCTAssertEqual(interceptStream.strings.count, 2)
        guard interceptStream.strings.count == 2 else {
            XCTFail("Intercepted \(interceptStream.strings.count) logs, expected 2")
            return
        }

        XCTAssert(interceptStream.strings[0].contains("a=a0 b=b0"), "LINES: \(interceptStream.strings[0])")
        XCTAssert(interceptStream.strings[1].contains("a=a1 b=b1"), "LINES: \(interceptStream.strings[1])")
    }

    func testStreamLogHandlerWritesIncludeMetadataProviderMetadata() {
        let interceptStream = InterceptStream()
        LoggingSystem.bootstrap(validate: false, metadataProvider: .exampleMetadataProvider) { _, metadataProvider in
            StreamLogHandler(label: "test", stream: interceptStream, metadataProvider: metadataProvider)
        }
        let log = Logger(label: "test")

        let testString = "my message is better than yours"
        log.error("\(testString)")

        let messageSucceeded = interceptStream.interceptedText?.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix(testString)

        XCTAssertTrue(messageSucceeded ?? false)
        XCTAssertEqual(interceptStream.strings.count, 1)
        let message = interceptStream.strings.first!
        XCTAssertTrue(message.contains("example=example-value"), "message must contain metadata, was: \(message)")
    }

    func testStdioOutputStreamWrite() {
        self.withWriteReadFDsAndReadBuffer { writeFD, readFD, readBuffer in
            let logStream = StdioOutputStream(file: writeFD, flushMode: .always)
            LoggingSystem.bootstrap(validate: false) { StreamLogHandler(label: $0, stream: logStream) }
            let log = Logger(label: "test")
            let testString = "hello\u{0} world"
            log.error("\(testString)")

            let size = read(readFD, readBuffer, 256)

            let output = String(decoding: UnsafeRawBufferPointer(start: UnsafeRawPointer(readBuffer), count: numericCast(size)), as: UTF8.self)
            let messageSucceeded = output.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix(testString)
            XCTAssertTrue(messageSucceeded)
        }
    }

    func testStdioOutputStreamFlush() {
        // flush on every statement
        self.withWriteReadFDsAndReadBuffer { writeFD, readFD, readBuffer in
            let logStream = StdioOutputStream(file: writeFD, flushMode: .always)
            LoggingSystem.bootstrap(validate: false) { StreamLogHandler(label: $0, stream: logStream) }
            Logger(label: "test").error("test")

            let size = read(readFD, readBuffer, 256)
            XCTAssertGreaterThan(size, -1, "expected flush")

            logStream.flush()
            let size2 = read(readFD, readBuffer, 256)
            XCTAssertEqual(size2, -1, "expected no flush")
        }
        // default flushing
        self.withWriteReadFDsAndReadBuffer { writeFD, readFD, readBuffer in
            let logStream = StdioOutputStream(file: writeFD, flushMode: .undefined)
            LoggingSystem.bootstrap(validate: false) { StreamLogHandler(label: $0, stream: logStream) }
            Logger(label: "test").error("test")

            let size = read(readFD, readBuffer, 256)
            XCTAssertEqual(size, -1, "expected no flush")

            logStream.flush()
            let size2 = read(readFD, readBuffer, 256)
            XCTAssertGreaterThan(size2, -1, "expected flush")
        }
    }

    func withWriteReadFDsAndReadBuffer(_ body: (CFilePointer, CInt, UnsafeMutablePointer<Int8>) -> Void) {
        var fds: [Int32] = [-1, -1]
        #if os(Windows)
        fds.withUnsafeMutableBufferPointer {
            let err = _pipe($0.baseAddress, 256, _O_BINARY)
            XCTAssertEqual(err, 0, "_pipe failed \(err)")
        }
        #else
        fds.withUnsafeMutableBufferPointer { ptr in
            let err = pipe(ptr.baseAddress!)
            XCTAssertEqual(err, 0, "pipe failed \(err)")
        }
        #endif

        let writeFD = fdopen(fds[1], "w")
        let writeBuffer = UnsafeMutablePointer<Int8>.allocate(capacity: 256)
        defer {
            writeBuffer.deinitialize(count: 256)
            writeBuffer.deallocate()
        }

        var err = setvbuf(writeFD, writeBuffer, _IOFBF, 256)
        XCTAssertEqual(err, 0, "setvbuf failed \(err)")

        let readFD = fds[0]
        #if os(Windows)
        let hPipe: HANDLE = HANDLE(bitPattern: _get_osfhandle(readFD))!
        XCTAssertFalse(hPipe == INVALID_HANDLE_VALUE)

        var dwMode: DWORD = DWORD(PIPE_NOWAIT)
        let bSucceeded = SetNamedPipeHandleState(hPipe, &dwMode, nil, nil)
        XCTAssertTrue(bSucceeded)
        #else
        err = fcntl(readFD, F_SETFL, fcntl(readFD, F_GETFL) | O_NONBLOCK)
        XCTAssertEqual(err, 0, "fcntl failed \(err)")
        #endif

        let readBuffer = UnsafeMutablePointer<Int8>.allocate(capacity: 256)
        defer {
            readBuffer.deinitialize(count: 256)
            readBuffer.deallocate()
        }

        // the actual test
        body(writeFD!, readFD, readBuffer)

        fds.forEach { close($0) }
    }

    func testOverloadingError() {
        struct Dummy: Error, LocalizedError {
            var errorDescription: String? {
                return "errorDescription"
            }
        }
        let logging = TestLogging()
        LoggingSystem.bootstrap(validate: false, logging.make)

        var logger = Logger(label: "test")
        logger.level = .error
        logger.error(error: Dummy())

        logging.history.assertExist(level: .error, message: "errorDescription")
    }

    func testCompileInitializeStandardStreamLogHandlersWithMetadataProviders() {
        // avoid "unreachable code" warnings
        let dontExecute = Int.random(in: 100 ... 200) == 1
        guard dontExecute else {
            return
        }

        // default usage
        LoggingSystem.bootstrap(validate: false, StreamLogHandler.standardOutput)
        LoggingSystem.bootstrap(validate: false, StreamLogHandler.standardError)

        // with metadata handler, explicitly, public api
        LoggingSystem.bootstrap(validate: false, metadataProvider: .exampleMetadataProvider) { label, metadataProvider in
            StreamLogHandler.standardOutput(label: label, metadataProvider: metadataProvider)
        }
        
        LoggingSystem.bootstrap(validate: false, metadataProvider: .exampleMetadataProvider) { label, metadataProvider in
            StreamLogHandler.standardError(label: label, metadataProvider: metadataProvider)
        }

        // with metadata handler, still pretty
        LoggingSystem.bootstrap(validate: false,
                                metadataProvider: .exampleMetadataProvider,
                                StreamLogHandler.standardOutput)
        LoggingSystem.bootstrap(validate: false,
                                metadataProvider: .exampleMetadataProvider, StreamLogHandler.standardError)
    }

}

extension Logger {
    #if compiler(>=5.3)
    func error(error: Error,
                      metadata: @autoclosure () -> Logger.Metadata? = nil,
                      file: String = #fileID, function: String = #function, line: UInt = #line) {
        self.error("\(error.localizedDescription)", metadata: metadata(), file: file, function: function, line: line)
    }

    #else
    func error(error: Error,
                      metadata: @autoclosure () -> Logger.Metadata? = nil,
                      file: String = #file, function: String = #function, line: UInt = #line) {
        self.error("\(error.localizedDescription)", metadata: metadata(), file: file, function: function, line: line)
    }
    #endif
}

extension Logger.MetadataProvider {
    static var exampleMetadataProvider: Self {
        .init { ["example": .string("example-value")] }
    }

    static func constant(_ metadata: Logger.Metadata) -> Self {
        .init { metadata }
    }
}

// Sendable

#if compiler(>=5.6)
// used to test logging metadata which requires Sendable conformance
// @unchecked Sendable since manages it own state
extension LoggingTest.LazyMetadataBox: @unchecked Sendable {}

// used to test logging stream which requires Sendable conformance
// @unchecked Sendable since manages it own state
extension LoggingTest.InterceptStream: @unchecked Sendable {}
#endif
