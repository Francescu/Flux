// MessageType.swift
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

public protocol MessageType {
    var majorVersion: Int { get set }
    var minorVersion: Int { get set }
    var headers: [String: String] { get set }
    var body: Data { get set }
    var storage: [String: Any] { get set }
}
extension MessageType {
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
            setHeader("Content-Type", value: newValue?.description)
        }
    }

    public var headerDescription: String {
        var string = ""

        for (index, (header, value)) in headers.enumerate() {
            string += "\(header): \(value)"

            if index < headers.count - 1 {
                string += "\n"
            }
        }

        return string
    }

    public var bodyDescription: String {
        if body.count == 0 {
            return "-"
        }
        
        return body.description
    }

    public var storageDescription: String {
        var string = "Storage:\n"

        if storage.count == 0 {
            string += "-"
        }

        for (index, (key, value)) in storage.enumerate() {
            string += "\(key): \(value)"

            if index < storage.count - 1 {
                string += "\n"
            }
        }

        return string
    }

    public var bodyString: String? {
        return try? String(data: body)
    }
}