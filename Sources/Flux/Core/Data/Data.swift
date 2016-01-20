// Data.swift
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

public typealias Byte = UInt8

public protocol DataConvertible {
    var data: Data { get }
}

public struct Data {
    public var bytes: [Byte]

    public init(bytes: [Byte]) {
        self.bytes = bytes
    }
}

extension Data: DataConvertible {
    public var data: Data {
        return self
    }
}

extension Data {
    public init() {
        self.bytes = []
    }

    public init(_ convertible: DataConvertible) {
        self.bytes = convertible.data.bytes
    }

    public init<S: SequenceType where S.Generator.Element == Byte>(_ bytes: S) {
        self.bytes = [Byte](bytes)
    }

    public init<C: CollectionType where C.Generator.Element == Byte>(_ bytes: C) {
        self.bytes = [Byte](bytes)
    }

    public mutating func replaceRange<C: CollectionType where C.Generator.Element == Byte>(subRange: Range<Int>, with newElements: C) {
        bytes.replaceRange(subRange, with: newElements)
    }

    public mutating func reserveCapacity(minimumCapacity: Int) {
        bytes.reserveCapacity(minimumCapacity)
    }

    public mutating func append(newElement: Byte) {
        bytes.append(newElement)
    }

    public mutating func appendContentsOf<S: SequenceType where S.Generator.Element == Byte>(newElements: S) {
        bytes.appendContentsOf(newElements)
    }

    public mutating func insert(newElement: Byte, atIndex i: Int) {
        bytes.insert(newElement, atIndex: i)
    }

    public mutating func insertContentsOf<S : CollectionType where S.Generator.Element == Byte>(newElements: S, at i: Int) {
        bytes.insertContentsOf(newElements, at: i)
    }

    public mutating func removeAtIndex(index: Int) -> Byte {
        return bytes.removeAtIndex(index)
    }

    public mutating func removeFirst() -> Byte {
        return bytes.removeFirst()
    }

    public mutating func removeFirst(n: Int) {
        bytes.removeFirst(n)
    }

    public mutating func removeRange(subRange: Range<Int>) {
        bytes.removeRange(subRange)
    }

    public mutating func removeAll(keepCapacity keepCapacity: Bool = true) {
        bytes.removeAll(keepCapacity: keepCapacity)
    }

    public init(count: Int, repeatedValue: Byte) {
        self.init(bytes: [Byte](count: count, repeatedValue: repeatedValue))
    }

    public var capacity: Int {
        return bytes.capacity
    }

    public var isEmpty: Bool {
        return bytes.isEmpty
    }
}

extension Data: MutableCollectionType {
    public func generate() -> AnyGenerator<Byte> {
        var index = 0
        return anyGenerator {
            let byte = self.bytes[safe: index]
            index += 1
            return byte
        }
    }

    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return count
    }

    public var count: Int {
        return bytes.count
    }

    public subscript(index: Int) -> Byte {
        get {
            return bytes[index]
        }

        set {
            bytes[index] = newValue
        }
    }

    public subscript (bounds: Range<Int>) -> ArraySlice<Byte> {
        get {
            return bytes[bounds]
        }

        set {
            bytes[bounds] = newValue
        }
    }
}

extension Data {
    public var hexDescription: String {
        var string = ""
        for (index, value) in self.enumerate() {
            if index % 2 == 0 && index > 0 {
                string += " "
            }
            string += (value < 16 ? "0" : "") + String(value, radix: 16)
        }
        return string
    }
}

extension Data: ArrayLiteralConvertible {
    public init(arrayLiteral bytes: Byte...) {
        self.init(bytes: bytes)
    }
}

extension Data: StringLiteralConvertible {
    public init(stringLiteral string: String) {
        self.init(bytes: [Byte](string.utf8))
    }

    public init(extendedGraphemeClusterLiteral string: String){
        self.init(bytes: [Byte](string.utf8))
    }

    public init(unicodeScalarLiteral string: String){
        self.init(bytes: [Byte](string.utf8))
    }
}

extension Data: StringInterpolationConvertible {
    public init(stringInterpolation data: Data...) {
        self.init(data.joinWithSeparator([]))
    }

    public init<T>(stringInterpolationSegment expr: T) {
        self.init("\(expr)")
    }

    public init(stringInterpolationSegment convertible: DataConvertible) {
        self.init(convertible.data)
    }

    public init<S: SequenceType where S.Generator.Element == Byte>(stringInterpolationSegment bytes: S) {
        self.init(bytes)
    }

    public init<C: CollectionType where C.Generator.Element == Byte>(stringInterpolationSegment bytes: C) {
        self.init(bytes)
    }
}

extension Data: CustomStringConvertible {
    public var description: String {
        if let string = String(data: self) {
            return string
        }

        return debugDescription
    }
}

extension Data: CustomDebugStringConvertible {
    public var debugDescription: String {
        return hexDescription
    }
}

extension Data: NilLiteralConvertible {
    public init(nilLiteral: Void) {
        self.init(bytes: [])
    }
}

extension Data {
    public func withUnsafeBufferPointer<R>(@noescape body: (UnsafeBufferPointer<Byte>) throws -> R) rethrows -> R {
        return try bytes.withUnsafeBufferPointer(body)
    }

    public mutating func withUnsafeMutableBufferPointer<R>(@noescape body: (inout UnsafeMutableBufferPointer<Byte>) throws -> R) rethrows -> R {
        return try bytes.withUnsafeMutableBufferPointer(body)
    }

    public mutating func popLast() -> Byte? {
        return bytes.popLast()
    }
}

public func +=<S : SequenceType where S.Generator.Element == Byte>(inout lhs: Data, rhs: S) {
    return lhs.bytes += rhs
}

public func +=(inout lhs: Data, rhs: DataConvertible) {
    return lhs.bytes += rhs.data.bytes
}

@warn_unused_result
public func +(lhs: DataConvertible, rhs: DataConvertible) -> Data {
    return Data(bytes: lhs.data.bytes + rhs.data.bytes)
}