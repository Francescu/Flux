// Response.swift
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

public struct Response {
    public var status: Status
    public var majorVersion: Int
    public var minorVersion: Int
    public var headers: [String: String]
    public var body: Data
    public var upgrade: (StreamType -> Void)?

    public var storage: [String: Any] = [:]

    init(status: Status, majorVersion: Int, minorVersion: Int, headers: [String: String], body: Data, upgrade: (StreamType -> Void)?) {
        self.status = status
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.headers = headers
        self.body = body
        self.upgrade = upgrade
    }
}

extension Response {
    public init(status: Status, headers: [String: String] = [:], body: Data = [], upgrade: (StreamType -> Void)? = nil) {
        var headers = headers
        headers["Content-Length"] = "\(body.count)"

        self.status = status
        self.majorVersion = 1
        self.minorVersion = 1
        self.headers = headers
        self.body = body
        self.upgrade = upgrade
    }

    public init(status: Status, headers: [String: String] = [:], body: DataConvertible, upgrade: (StreamType -> Void)? = nil) {
        self.init(
            status: status,
            headers: headers,
            body: body.data,
            upgrade: upgrade
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

    public var contentType: MediaType? {
        get {
            if let contentType = getHeader("content-type") {
                return MediaType(string: contentType)
            }
            return nil
        }

        set {
            setHeader("content-type", value: newValue?.description)
        }
    }

    public var statusCode: Int {
        return status.statusCode
    }

    public var reasonPhrase: String {
        return status.reasonPhrase
    }

    public var bodyString: String? {
        return String(data: body)
    }

    public var bodyHexString: String {
        return body.hexString
    }
}

extension Response: CustomStringConvertible {
    public var description: String {
        var string = "HTTP/1.1 \(statusCode) \(reasonPhrase)\n"

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

extension Response: CustomDebugStringConvertible {
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

extension Response: Hashable {
    public var hashValue: Int {
        return description.hashValue
    }
}

public func ==(lhs: Response, rhs: Response) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
