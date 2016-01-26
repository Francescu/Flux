// Log.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


public let log = Log()

public final class Log {
    public struct Level: OptionSetType {
        public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }

        public static let Trace   = Level(rawValue: 1 << 0)
        public static let Debug   = Level(rawValue: 1 << 1)
        public static let Info    = Level(rawValue: 1 << 2)
        public static let Warning = Level(rawValue: 1 << 3)
        public static let Error   = Level(rawValue: 1 << 4)
        public static let Fatal   = Level(rawValue: 1 << 5)
    }

    public var stream: File
    public var levels: Level
    private let messageChannel = Channel<String>()
    private let errorChannel = FallibleChannel<Void>()
    private let once = Once()

    public init(stream: File = standardErrorStream, levels: Level = [.Trace, .Debug, .Info, .Warning, .Error, .Fatal]) {
        self.stream = stream
        self.levels = levels
    }

    deinit {
        messageChannel.close()
        errorChannel.close()
    }

    public func log(level: Level, item: Any, terminator: String = "\n", flush: Bool = true) throws {
        if levels.contains(level) {
            once.runInBackground {
                for message in self.messageChannel {
                    do {
                        try self.stream.write(message)
                        self.errorChannel.send()
                    } catch {
                        self.errorChannel.sendError(error)
                    }
                }
            }
            messageChannel.send(String(item) + terminator)
            try errorChannel.receive()
        }
    }

    public func trace(item: Any, terminator: String = "\n", flush: Bool = true) throws {
        try log(.Trace, item: item, terminator: terminator, flush: flush)
    }

    public func debug(item: Any, terminator: String = "\n", flush: Bool = true) throws {
        try log(.Debug, item: item, terminator: terminator, flush: flush)
    }

    public func info(item: Any, terminator: String = "\n", flush: Bool = true) throws {
        try log(.Info, item: item, terminator: terminator, flush: flush)
    }

    public func warning(item: Any, terminator: String = "\n", flush: Bool = true) throws {
        try log(.Warning, item: item, terminator: terminator, flush: flush)
    }

    public func error(item: Any, terminator: String = "\n", flush: Bool = true) throws {
        try log(.Error, item: item, terminator: terminator, flush: flush)
    }

    public func fatal(item: Any, terminator: String = "\n", flush: Bool = true) throws {
        try log(.Fatal, item: item, terminator: terminator, flush: flush)
    }
}