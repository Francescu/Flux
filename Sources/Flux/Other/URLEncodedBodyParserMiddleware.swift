// URLEncodedFormParserMiddleware.swift
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

enum URLEncodedBodyError: ErrorType {
    case URLEncodedBodyNotFound
}

extension Request {
    private var URLEncodedBodyKey: String {
        return "URLEncodedBody"
    }

    public var URLEncodedBody: [String: String] {
        set {
            storage[URLEncodedBodyKey] = newValue
        }
        get {
            return storage[URLEncodedBodyKey] as? [String: String] ?? [:]
        }
    }

    public func getURLEncodedBody() throws -> [String: String] {
        guard let URLEncodedBody = storage[URLEncodedBodyKey] as? [String: String] else {
            throw URLEncodedBodyError.URLEncodedBodyNotFound
        }

        return URLEncodedBody
    }
}


public struct URLEncodedBodyParserMiddleware: MiddlewareType {
    public init() {}
    
    public func respond(request: Request, chain: ChainType) throws -> Response {
        var request = request

        if let
            mediaType = request.contentType,
            bodyString = request.bodyString
            where mediaType == URLEncodedFormMediaType  {
                request.storage["URLEncodedBody"] = self.parseURLEncodedString(bodyString)
        }

        return try chain.proceed(request)
    }

    private func parseURLEncodedString(string: String) -> [String: String] {
        var parameters: [String: String] = [:]

        for parameter in string.splitBy("&") {
            let tokens = parameter.splitBy("=")

            if tokens.count >= 2 {
                let key = try? String(URLEncodedString: tokens[0])
                let value = try? String(URLEncodedString: tokens[1])

                if let key = key, value = value {
                    parameters[key] = value
                }
            }
        }

        return parameters
    }
}