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

public struct Request: MessageType {
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
    public init(method: Method, uri: URI, headers: [String: String] = [:], body convertible: DataConvertible = Data()) {
        var headers = headers
        headers["Content-Length"] = "\(convertible.data.count)"

        self.init(
            method: method,
            uri: uri,
            majorVersion: 1,
            minorVersion: 1,
            headers: headers,
            body: convertible.data
        )
    }

    public init(method: Method, uri: String, headers: [String: String] = [:], body convertible: DataConvertible = Data()) throws {
        self.init(
            method: method,
            uri: try URI(string: uri),
            headers: headers,
            body: convertible.data
        )
    }

    public var connection: String? {
        return getHeader("Connection")?.lowercaseString
    }

    public var isKeepAlive: Bool {
        if minorVersion == 0 {
            return connection == "keep-alive"
        }

        return connection != "close"
    }

    public var isUpgrade: Bool {
        return connection == "upgrade"
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

    public var path: String? {
        return uri.path
    }

    public var query: [String: String] {
        return uri.query
    }
}

extension Request: CustomStringConvertible {
    public var requestLineDescription: String {
        return "\(method) \(uri) HTTP/\(majorVersion).\(minorVersion)"
    }

    public var description: String {
        return requestLineDescription + "\n" +
            headerDescription + "\n\n" +
            bodyDescription
    }
}

extension Request: CustomDebugStringConvertible {
    public var debugDescription: String {
        return description + "\n\n" + storageDescription
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