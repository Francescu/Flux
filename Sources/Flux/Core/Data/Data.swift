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

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public typealias Byte = UInt8

public protocol DataConvertible {
    var data: Data { get }
    init(data: Data) throws
}

public protocol UnsafeDataConvertible: DataConvertible {}

public extension UnsafeDataConvertible {
    public var data: Data {
        return Data(value: self)
    }

    public init(data: Data) {
        self = data.convert()
    }
}

public struct Data {
    private var bytes: [Byte]

    public init(bytes: [Byte]) {
        self.bytes = bytes
    }
}

extension Int: UnsafeDataConvertible {}
extension UInt: UnsafeDataConvertible {}
extension Float: UnsafeDataConvertible {}
extension Double: UnsafeDataConvertible {}

extension Data {
    public init() {
        self.bytes = []
    }
    
    init<T>(pointer: UnsafePointer<T>, length: Int){
        assert(sizeof(pointer.memory.dynamicType) == sizeof(Byte.self), "Cannot create array of bytes from pointer to \(pointer.memory.dynamicType) because the type is larger than a single byte.")
        
        var buffer: [UInt8] = [UInt8](count: length, repeatedValue: 0)
        
        memcpy(&buffer, pointer, length)
        
        self.bytes = buffer
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
}

extension Data: MutableCollectionType {
    public func generate() -> AnyGenerator<Byte> {
        var index = 0
        return AnyGenerator {
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

    public subscript (bounds: Range<Int>) -> Data {
        get {
            return Data(bytes[bounds])
        }

        set {
            bytes[bounds] = ArraySlice<Byte>(newValue.bytes)
        }
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

extension Data: CustomStringConvertible {
    public var description: String {
        if let string = try? String(data: self) {
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
    internal func convert<T>() -> T {
        return bytes.withUnsafeBufferPointer {
            return UnsafePointer<T>($0.baseAddress).memory
        }
    }

    internal init<T>(value: T) {
        var value = value
        self.bytes = withUnsafePointer(&value) {
            Array(UnsafeBufferPointer(start: UnsafePointer<Byte>($0), count: sizeof(T)))
        }
    }

    public func withUnsafeBufferPointer<R>(@noescape body: (UnsafeBufferPointer<Byte>) throws -> R) rethrows -> R {
        return try bytes.withUnsafeBufferPointer(body)
    }

    public mutating func withUnsafeMutableBufferPointer<R>(@noescape body: (inout UnsafeMutableBufferPointer<Byte>) throws -> R) rethrows -> R {
        return try bytes.withUnsafeMutableBufferPointer(body)
    }

    public static func bufferWithSize(size: Int) -> Data {
        return Data([UInt8](count: size, repeatedValue: 0))
    }


    public mutating func replaceBytesInRange<C: CollectionType where C.Generator.Element == Byte>(subRange: Range<Int>, with newBytes: C) {
        bytes.replaceRange(subRange, with: newBytes)
    }

    public mutating func reserveCapacity(minimumCapacity: Int) {
        bytes.reserveCapacity(minimumCapacity)
    }

    public mutating func appendByte(newByte: Byte) {
        bytes.append(newByte)
    }

    public mutating func appendBytes<S: SequenceType where S.Generator.Element == Byte>(newBytes: S) {
        bytes.appendContentsOf(newBytes)
    }

    public mutating func insertByte(newByte: Byte, atIndex i: Int) {
        bytes.insert(newByte, atIndex: i)
    }

    public mutating func insertBytes<S : CollectionType where S.Generator.Element == Byte>(newBytes: S, at i: Int) {
        bytes.insertContentsOf(newBytes, at: i)
    }

    public mutating func removeByteAtIndex(index: Int) -> Byte {
        return bytes.removeAtIndex(index)
    }

    public mutating func removeFirstByte() -> Byte {
        return bytes.removeFirst()
    }

    public mutating func removeFirstBytes(n: Int) {
        bytes.removeFirst(n)
    }

    public mutating func removeBytesInRange(subRange: Range<Int>) {
        bytes.removeRange(subRange)
    }

    public mutating func removeAllBytes(keepCapacity keepCapacity: Bool = true) {
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

    public mutating func popLastByte() -> Byte? {
        return bytes.popLast()
    }
}

public func +=<S : SequenceType where S.Generator.Element == Byte>(inout lhs: Data, rhs: S) {
    return lhs.bytes += rhs
}

public func +=(inout lhs: Data, rhs: Data) {
    return lhs.bytes += rhs.bytes
}

public func +=(inout lhs: Data, rhs: DataConvertible) {
    return lhs += rhs.data
}

@warn_unused_result
public func +(lhs: Data, rhs: Data) -> Data {
    return Data(bytes: lhs.bytes + rhs.bytes)
}

@warn_unused_result
public func +(lhs: Data, rhs: DataConvertible) -> Data {
    return lhs + rhs.data
}

@warn_unused_result
public func +(lhs: DataConvertible, rhs: Data) -> Data {
    return lhs.data + rhs
}

extension CollectionType {
    subscript (safe index: Self.Index) -> Self.Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}