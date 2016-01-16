// Request.swift
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

public struct Request {
    public var method: Method
    public var uri: URI
    public var majorVersion: Int
    public var minorVersion: Int
    public var headers: [String: String]
    public var body: Data

    public var storage: [String: Any] = [:]

    init(method: Method, uri: URI, majorVersion: Int, minorVersion: Int, headers: [String: String], body: Data) {
        self.method = method
        self.uri = uri
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.headers = headers
        self.body = body
    }
}

extension Request {
    public init(method: Method, uri: URI, headers: [String: String] = [:], body: Data = []) {
        var headers = headers
        headers["Content-Length"] = "\(body.count)"
        
        self.method = method
        self.uri = uri
        self.majorVersion = 1
        self.minorVersion = 1
        self.headers = headers
        self.body = body
    }

    public init(method: Method, uri: URI, headers: [String: String] = [:], body: DataConvertible) {
        self.init(
            method: method,
            uri: uri,
            headers: headers,
            body: body.data
        )
    }

    public init(method: Method, uri: String, headers: [String: String] = [:], body: Data = []) throws {
        self.init(
            method: method,
            uri: try URI(string: uri),
            headers: headers,
            body: body
        )
    }

    public init(method: Method, uri: String, headers: [String: String] = [:], body: DataConvertible) throws {
        self.init(
            method: method,
            uri: try URI(string: uri),
            headers: headers,
            body: body.data
        )
    }

    public func getHeader(header: String) -> String? {
        for (key, value) in headers where key.lowercaseString == header.lowercaseString {
            return value
        }
        return nil
    }

    public mutating func setHeader(header: String, value: String?) {
        self.headers[header] = value
    }

    public var isKeepAlive: Bool {
        if minorVersion == 0 {
            return getHeader("Connection")?.lowercaseString == "keep-alive"
        } else {
            return getHeader("Connection")?.lowercaseString != "close"
        }
    }

    public var isUpgrade: Bool {
        return getHeader("Connection")?.lowercaseString == "upgrade"
    }

    public var contentType: MediaType? {
        get {
            if let contentType = getHeader("content-type") {
                return MediaType(string: contentType)
            }
            return nil
        }

        set {
            setHeader("Content-Type", value: newValue?.description)
        }
    }

    public var accept: [MediaType] {
get {
            var acceptedMediaTypes: [MediaType] = []

            if let acceptString = getHeader("accept") {
                let acceptedTypesString = acceptString.splitBy(",")

                for acceptedTypeString in acceptedTypesString {
                    let acceptedTypeTokens = acceptedTypeString.splitBy(";")

                    if acceptedTypeTokens.count >= 1 {
                        let mediaTypeString = acceptedTypeTokens[0].trim()
                        acceptedMediaTypes.append(MediaType(string: mediaTypeString))
                    }
                }
            }

            return acceptedMediaTypes
        }

        set {
            let header = newValue.map({"\($0.type)/\($0.subtype)"}).joinWithSeparator(", ")
            setHeader("Accept", value: header)
        }
    }

    public var path: String {
        return uri.path!
    }

    public var query: [String: String] {
        return uri.query
    }

    public var bodyString: String? {
        return String(data: body)
    }

    public var bodyHexString: String {
        return body.hexString
    }
}

extension Request: CustomStringConvertible {
    public var description: String {
        var string = "\(method) \(uri) HTTP/\(majorVersion).\(minorVersion)\n"

        for (header, value) in headers {
            string += "\(header): \(value)\n"
        }

        if body.count > 0 {
            if let bodyString = bodyString {
                string += "\n" + bodyString
            } else  {
                string += "\n" + bodyHexString
            }
        }
        
        return string
    }
}

extension Request: CustomDebugStringConvertible {
    public var debugDescription: String {
        var string = description

        string += "\n\nStorage:\n"

        if storage.count == 0 {
            string += "-\n"
        }

        for (key, value) in storage {
            string += "\(key): \(value)\n"
        }

        return string
    }
}

extension Request: Hashable {
    public var hashValue: Int {
        return description.hashValue
    }
}

public func ==(lhs: Request, rhs: Request) -> Bool {
    return lhs.hashValue == rhs.hashValue
}