// ServerType.swift
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

public protocol StreamServerType {
    func accept() throws -> StreamType
}

public protocol RequestStreamParserType {
    func parse(data: Data) throws -> Request?
}

public protocol ResponseStreamSerializerType {
    func serialize(stream: StreamType, response: Response) throws
}

public protocol ServerType {
    var server: StreamServerType { get }
    var parser: RequestStreamParserType { get }
    var responder: ResponderType { get }
    var serializer: ResponseStreamSerializerType  { get }
}

extension ServerType {
    public func start(failure: ErrorType -> Void = Self.logError) throws {
        while true {
            let stream = try server.accept()

            do {
                try processStream(stream)
            } catch {
                failure(error)
            }
        }
    }

    private func processStream(stream: StreamType) throws {
        while !stream.closed {
            do {
                let data = try stream.receive()
                if let request = try parser.parse(data) {
                    let response = try responder.respond(request)
                    try serializer.serialize(stream, response: response)

                    if let upgrade = response.upgrade {
                        try upgrade(stream)
                        stream.close()
                    }

                    if !request.isKeepAlive {
                        stream.close()
                        break
                    }
                }
            } catch StreamError.ClosedStream {
                break
            }
        }
    }

    public func startInBackground(failure: ErrorType -> Void = Self.logError) {
        co {
            do {
                try self.start()
            } catch {
                failure(error)
            }
        }
    }

    private static func logError(e: ErrorType) -> Void {
        log.error("Error: \(e)")
    }
}
