// RequestParser.swift
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

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif
import CHTTPParser

struct ResponseParserContext {
    var statusCode: Int = 0
    var reasonPhrase: String = ""
    var majorVersion: Int = 0
    var minorVersion: Int = 0
    var headers: [String: String] = [:]
    var body: Data = []

    var buildingHeaderField = ""
    var currentHeaderField = ""
    var completion: Response -> Void

    init(completion: Response -> Void) {
        self.completion = completion
    }
}

var responseSettings: http_parser_settings = {
    var settings = http_parser_settings()
    http_parser_settings_init(&settings)

    settings.on_status           = onResponseStatus
    settings.on_header_field     = onResponseHeaderField
    settings.on_header_value     = onResponseHeaderValue
    settings.on_headers_complete = onResponseHeadersComplete
    settings.on_body             = onResponseBody
    settings.on_message_complete = onResponseMessageComplete

    return settings
}()

public final class ResponseParser {
    let completion: Response -> Void
    let context: UnsafeMutablePointer<ResponseParserContext>
    var parser = http_parser()

    public init(completion: Response -> Void) {
        self.completion = completion

        self.context = UnsafeMutablePointer<ResponseParserContext>.alloc(1)
        self.context.initialize(ResponseParserContext(completion: completion))

        http_parser_init(&self.parser, HTTP_RESPONSE)
        self.parser.data = UnsafeMutablePointer<Void>(context)
    }

    deinit {
        context.destroy()
        context.dealloc(1)
    }

    public func parse(data: UnsafeMutablePointer<Void>, length: Int) throws {
        let bytesParsed = http_parser_execute(&parser, &responseSettings, UnsafeMutablePointer<Int8>(data), length)

        if bytesParsed != length {
            let errorName = http_errno_name(http_errno(parser.http_errno))
            let errorDescription = http_errno_description(http_errno(parser.http_errno))
            let error = ParseError(description: "\(String.fromCString(errorName)!): \(String.fromCString(errorDescription)!)")
            throw error
        }
    }
}

extension ResponseParser {
    public func parse(data: Data) throws {
        var data = data
        try parse(&data, length: data.count)
    }

    public func parse(string: String) throws {
        var data = string.utf8.map { Int8($0) }
        try parse(&data, length: data.count)
    }

    public func eof() throws {
        try parse(nil, length: 0)
    }
}

func onResponseStatus(parser: UnsafeMutablePointer<http_parser>, data: UnsafePointer<Int8>, length: Int) -> Int32 {
    let context = UnsafeMutablePointer<ResponseParserContext>(parser.memory.data)

    var buffer: [Int8] = [Int8](count: length + 1, repeatedValue: 0)
    strncpy(&buffer, data, length)
    context.memory.reasonPhrase += String.fromCString(buffer)!

    return 0

}

func onResponseHeaderField(parser: UnsafeMutablePointer<http_parser>, data: UnsafePointer<Int8>, length: Int) -> Int32 {
    let context = UnsafeMutablePointer<ResponseParserContext>(parser.memory.data)

    var buffer: [Int8] = [Int8](count: length + 1, repeatedValue: 0)
    strncpy(&buffer, data, length)
    context.memory.buildingHeaderField += String.fromCString(buffer)!

    return 0
}

func onResponseHeaderValue(parser: UnsafeMutablePointer<http_parser>, data: UnsafePointer<Int8>, length: Int) -> Int32 {
    let context = UnsafeMutablePointer<ResponseParserContext>(parser.memory.data)

    var buffer: [Int8] = [Int8](count: length + 1, repeatedValue: 0)
    strncpy(&buffer, data, length)
    if context.memory.buildingHeaderField != "" {
        context.memory.currentHeaderField = context.memory.buildingHeaderField
    }
    context.memory.buildingHeaderField = ""
    let headerField = context.memory.currentHeaderField
    let previousHeaderValue = context.memory.headers[headerField] ?? ""
    context.memory.headers[headerField] = previousHeaderValue + String.fromCString(buffer)!

    return 0
}

func onResponseHeadersComplete(parser: UnsafeMutablePointer<http_parser>) -> Int32 {
    let context = UnsafeMutablePointer<ResponseParserContext>(parser.memory.data)

    context.memory.buildingHeaderField = ""
    context.memory.currentHeaderField = ""
    context.memory.statusCode = Int(parser.memory.status_code)
    context.memory.majorVersion = Int(parser.memory.http_major)
    context.memory.minorVersion = Int(parser.memory.http_minor)

    return 0
}

func onResponseBody(parser: UnsafeMutablePointer<http_parser>, data: UnsafePointer<Int8>, length: Int) -> Int32 {
    let context = UnsafeMutablePointer<ResponseParserContext>(parser.memory.data)

    var buffer: Data = Data(count: length, repeatedValue: 0)
    memcpy(&buffer, data, length)
    context.memory.body += buffer

    return 0
}

func onResponseMessageComplete(parser: UnsafeMutablePointer<http_parser>) -> Int32 {
    let context = UnsafeMutablePointer<ResponseParserContext>(parser.memory.data)

    let response = Response(
        status: Status(statusCode: context.memory.statusCode, reasonPhrase: context.memory.reasonPhrase),
        majorVersion: context.memory.majorVersion,
        minorVersion: context.memory.minorVersion,
        headers: context.memory.headers,
        body: context.memory.body,
        upgrade: nil
    )

    context.memory.completion(response)

    context.memory.statusCode = 0
    context.memory.reasonPhrase = ""
    context.memory.majorVersion = 0
    context.memory.minorVersion = 0
    context.memory.headers = [:]
    context.memory.body = []

    return 0
}
