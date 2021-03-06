// Result.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Formbound
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

import Foundation

public enum QueryParameter {
    case Binary([UInt8])
    case Text(String)
}

public protocol QueryParameterConvertible {
    var queryParameterValue: QueryParameter { get }
}

extension Int: QueryParameterConvertible {
    public var queryParameterValue: QueryParameter {
        return .Text(String(self))
    }
}

extension UInt: QueryParameterConvertible {
    public var queryParameterValue: QueryParameter {
        return .Text(String(self))
    }
}

extension Double: QueryParameterConvertible {
    public var queryParameterValue: QueryParameter {
        return .Text(String(self))
    }
}
extension Float: QueryParameterConvertible {
    public var queryParameterValue: QueryParameter {
        return .Text(String(self))
    }
}

extension String: QueryParameterConvertible {
    public var queryParameterValue: QueryParameter {
        return .Text(self)
    }
}

extension NSData: QueryParameterConvertible {
    public var queryParameterValue: QueryParameter {
        
        var a = [UInt8](count: length / sizeof(UInt8), repeatedValue: 0)
        getBytes(&a, length: length)
        
        return .Binary(a)
    }
}