// HTTPClientType.swift
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

public protocol StreamClientType {
    var host: String { get }
    var port: UInt16 { get }
    func connect() throws -> StreamType
}

public protocol RequestStreamSerializerType {
    func serialize(request: Request, stream: StreamType) throws
}

public protocol ResponseStreamParserType {
    func parse(stream: StreamType, completion: (Void throws -> Response) -> Void)
}

public protocol ClientType: ResponderType {
    var client: StreamClientType { get }
    var serializer: RequestStreamSerializerType { get }
    var parser: ResponseStreamParserType { get }
}

extension ClientType {
    public func respond(request: Request) throws -> Response {
        var request = request
        request.headers["Host"] = "\(client.host):\(client.port)"

        let stream = try client.connect()
        try serializer.serialize(request, stream: stream)
        let channel = FallibleChannel<Response>()

        co {
            self.parser.parse(stream) { getResponse in
                do {
                    let response = try getResponse()
                    channel.send(response)
                } catch {
                    channel.sendError(error)
                }
            }
        }

        return try channel.receive()!
    }

    public func send(request: Request, middleware: MiddlewareType...) throws -> Response {
        return try middleware.intercept(self).respond(request)
    }

    public func send(request: Request, middleware: [MiddlewareType]) throws -> Response {
        return try middleware.intercept(self).respond(request)
    }
}

extension ClientType {
    public func sendMethod(method: Method, uri: String, headers: [String: String] = [:], body: Data = [], middleware: MiddlewareType...) throws -> Response {
        let request = try Request(method: method, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func sendMethod(method: Method, uri: String, headers: [String: String] = [:], body: DataConvertible, middleware: MiddlewareType...) throws -> Response {
        let request = try Request(method: method, uri: uri, headers: headers, body: body.data)
        return try send(request, middleware: middleware)
    }

    public func sendMethod(method: Method, uri: String, headers: [String: String] = [:], body: Data = [], middleware: [MiddlewareType]) throws -> Response {
        let request = try Request(method: method, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func sendMethod(method: Method, uri: String, headers: [String: String] = [:], body: DataConvertible, middleware: [MiddlewareType]) throws -> Response {
        let request = try Request(method: method, uri: uri, headers: headers, body: body.data)
        return try send(request, middleware: middleware)
    }
}

extension ClientType {

    public func get(uri: String, headers: [String: String] = [:], body: Data = [], middleware: MiddlewareType...) throws -> Response {
        let request = try Request(method: .GET, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func get(uri: String, headers: [String: String] = [:], body: DataConvertible, middleware: MiddlewareType...) throws -> Response {
        let request = try Request(method: .GET, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func get(uri: String, headers: [String: String] = [:], body: Data = [], middleware: [MiddlewareType]) throws -> Response {
        let request = try Request(method: .GET, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func get(uri: String, headers: [String: String] = [:], body: DataConvertible, middleware: [MiddlewareType]) throws -> Response {
        let request = try Request(method: .GET, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }
}

extension ClientType {
    public func post(uri: String, headers: [String: String] = [:], body: Data = [], middleware: MiddlewareType...) throws -> Response {
        let request = try Request(method: .POST, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func post(uri: String, headers: [String: String] = [:], body: DataConvertible, middleware: MiddlewareType...) throws -> Response {
        let request = try Request(method: .POST, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func post(uri: String, headers: [String: String] = [:], body: Data = [], middleware: [MiddlewareType]) throws -> Response {
        let request = try Request(method: .POST, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func post(uri: String, headers: [String: String] = [:], body: DataConvertible, middleware: [MiddlewareType]) throws -> Response {
        let request = try Request(method: .POST, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }
}

extension ClientType {
    public func put(uri: String, headers: [String: String] = [:], body: Data = [], middleware: MiddlewareType...) throws -> Response {
        let request = try Request(method: .PUT, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func put(uri: String, headers: [String: String] = [:], body: DataConvertible, middleware: MiddlewareType...) throws -> Response {
        let request = try Request(method: .PUT, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func put(uri: String, headers: [String: String] = [:], body: Data = [], middleware: [MiddlewareType]) throws -> Response {
        let request = try Request(method: .PUT, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func put(uri: String, headers: [String: String] = [:], body: DataConvertible, middleware: [MiddlewareType]) throws -> Response {
        let request = try Request(method: .PUT, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }
}

extension ClientType {
    public func patch(uri: String, headers: [String: String] = [:], body: Data = [], middleware: MiddlewareType...) throws -> Response {
        let request = try Request(method: .PATCH, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func patch(uri: String, headers: [String: String] = [:], body: DataConvertible, middleware: MiddlewareType...) throws -> Response {
        let request = try Request(method: .PATCH, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func patch(uri: String, headers: [String: String] = [:], body: Data = [], middleware: [MiddlewareType]) throws -> Response {
        let request = try Request(method: .PATCH, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func patch(uri: String, headers: [String: String] = [:], body: DataConvertible, middleware: [MiddlewareType]) throws -> Response {
        let request = try Request(method: .PATCH, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }
}

extension ClientType {
    public func delete(uri: String, headers: [String: String] = [:], body: Data = [], middleware: MiddlewareType...) throws -> Response {
        let request = try Request(method: .DELETE, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func delete(uri: String, headers: [String: String] = [:], body: DataConvertible, middleware: MiddlewareType...) throws -> Response {
        let request = try Request(method: .DELETE, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func delete(uri: String, headers: [String: String] = [:], body: Data = [], middleware: [MiddlewareType]) throws -> Response {
        let request = try Request(method: .DELETE, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }

    public func delete(uri: String, headers: [String: String] = [:], body: DataConvertible, middleware: [MiddlewareType]) throws -> Response {
        let request = try Request(method: .DELETE, uri: uri, headers: headers, body: body)
        return try send(request, middleware: middleware)
    }
}