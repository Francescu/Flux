//  Row.swift
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


public protocol SQLValueConvertible {
    init(data: Data)
}

public protocol Row {
    typealias ValueType: Value
    
    init(valuesByName: [String: ValueType])
    
    var valuesByName: [String: ValueType] { get }
    
    subscript(fieldName: String) -> ValueType? { get }
}

public extension Row {
    public subscript(fieldName: String) -> ValueType? {
        return valuesByName[fieldName]
    }
    
    public func valueWithFieldName<T: SQLValueConvertible>(fieldName: String) throws -> T? {
        guard let value = valuesByName[fieldName] as? Data else {
            fatalError()
        }
        
        return T(data: value)
        
    }
}