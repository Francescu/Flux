// URLEncodedFormSerializer.swift
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

enum URLEncodedFormSerializeError: ErrorType {
    case InvalidInterchangeData
}

public struct URLEncodedFormSerializer: InterchangeDataSerializer {
    public init() {}

    public func serialize(interchangeData: InterchangeData) throws -> Data {
        return try serializeToString(interchangeData).data
    }

    public func serializeToString(interchangeData: InterchangeData) throws -> String {
        switch interchangeData {
        case .NullValue: throw URLEncodedFormSerializeError.InvalidInterchangeData
        case .BooleanValue: throw URLEncodedFormSerializeError.InvalidInterchangeData
        case .NumberValue: throw URLEncodedFormSerializeError.InvalidInterchangeData
        case .StringValue: throw URLEncodedFormSerializeError.InvalidInterchangeData
        case .ArrayValue: throw URLEncodedFormSerializeError.InvalidInterchangeData
        case .ObjectValue(let object): return try serializeObject(object)
        }
    }

    func serializeObject(object: [String: InterchangeData]) throws -> String {
        var string = ""

        for (index, (key, value)) in object.enumerate() {
            switch value {
            case .NullValue: throw URLEncodedFormSerializeError.InvalidInterchangeData
            case .BooleanValue: throw URLEncodedFormSerializeError.InvalidInterchangeData
            case .NumberValue: throw URLEncodedFormSerializeError.InvalidInterchangeData
            case .StringValue(let s):
                if index != 0 {
                    string += "&"
                }

                string += "\(key)=\(s)"
            case .ArrayValue: throw URLEncodedFormSerializeError.InvalidInterchangeData
            case .ObjectValue: throw URLEncodedFormSerializeError.InvalidInterchangeData
            }
        }

        return string
    }
}
