// MediaType.swift
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

enum MediaTypeError: ErrorType {
    case MalformedMediaTypeString
}

public struct MediaType: CustomStringConvertible {
    public let type: String
    public let subtype: String
    public let parameters: [String: String]

    public init(type: String, subtype: String, parameters: [String: String] = [:]) {
        self.type = type
        self.subtype = subtype
        self.parameters = parameters
    }

    public var description: String {
        var string = "\(type)/\(subtype)"

        if parameters.count > 0 {
            string += parameters.reduce(";") { $0 + " \($1.0)=\($1.1)" }
        }

        return string
    }

    public init(string: String) {
        let mediaTypeTokens = string.splitBy(";")

        let mediaType = mediaTypeTokens.first!
        var parameters: [String: String] = [:]

        if mediaTypeTokens.count == 2 {
            let parametersTokens = mediaTypeTokens[1].trim().splitBy(" ")

            for parametersToken in parametersTokens {
                let parameterTokens = parametersToken.splitBy("=")

                if parameterTokens.count == 2 {
                    let key = parameterTokens[0]
                    let value = parameterTokens[1]
                    parameters[key] = value
                }
            }
        }

        let tokens = mediaType.splitBy("/")

        self.type = tokens[0].lowercaseString
        self.subtype = tokens[1].lowercaseString
        self.parameters = parameters
    }

    public func matches(mediaType: MediaType) -> Bool {
        if type == "*" || mediaType.type == "*" {
            return true
        }

        if type == mediaType.type {
            if subtype == "*" || mediaType.subtype == "*" {
                return true
            }

            return subtype == mediaType.subtype
        }
        
        return false
    }
}

extension MediaType: Hashable {
    public var hashValue: Int {
        return type.hashValue ^ subtype.hashValue
    }
}

public func ==(lhs: MediaType, rhs: MediaType) -> Bool {
    return lhs.type == rhs.type && lhs.subtype == rhs.subtype
}

public let JSONMediaType = MediaType(type: "application", subtype: "json", parameters: ["charset": "utf-8"])
public let XMLMediaType = MediaType(type: "application", subtype: "xml", parameters: ["charset": "utf-8"])
public let URLEncodedFormMediaType = MediaType(type: "application", subtype: "x-www-form-urlencoded")
public let multipartFormMediaType = MediaType(type: "multipart", subtype: "form-data")