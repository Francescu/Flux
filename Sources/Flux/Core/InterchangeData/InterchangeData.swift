// InterchangeData.swift
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

public protocol InterchangeDataParser {
    func parse(data: Data) throws -> InterchangeData
}

public extension InterchangeDataParser {
    public func parse(convertible: DataConvertible) throws -> InterchangeData {
        return try parse(convertible.data)
    }
}

public protocol InterchangeDataSerializer {
    func serialize(interchangeData: InterchangeData) throws -> Data
}

public enum InterchangeData {
    case NullValue
    case BooleanValue(Bool)
    case NumberValue(Double)
    case StringValue(String)
    case ArrayValue([InterchangeData])
    case ObjectValue([String: InterchangeData])

    public static func from(value: Bool) -> InterchangeData {
        return .BooleanValue(value)
    }

    public static func from(value: Double) -> InterchangeData {
        return .NumberValue(value)
    }

    public static func from(value: Int) -> InterchangeData {
        return .NumberValue(Double(value))
    }

    public static func from(value: String) -> InterchangeData {
        return .StringValue(value)
    }

    public static func from(value: [InterchangeData]) -> InterchangeData {
        return .ArrayValue(value)
    }

    public static func from(value: [String: InterchangeData]) -> InterchangeData {
        return .ObjectValue(value)
    }

    public var isBoolean: Bool {
        switch self {
        case .BooleanValue: return true
        default: return false
        }
    }

    public var isNumber: Bool {
        switch self {
        case .NumberValue: return true
        default: return false
        }
    }

    public var isString: Bool {
        switch self {
        case .StringValue: return true
        default: return false
        }
    }

    public var isArray: Bool {
        switch self {
        case .ArrayValue: return true
        default: return false
        }
    }

    public var isObject: Bool {
        switch self {
        case .ObjectValue: return true
        default: return false
        }
    }

    public var bool: Bool? {
        switch self {
        case .BooleanValue(let b): return b
        default: return nil
        }
    }

    public var double: Double? {
        switch self {
        case .NumberValue(let n): return n
        default: return nil
        }
    }

    public var int: Int? {
        if let v = double {
            return Int(v)
        }
        return nil
    }

    public var uint: UInt? {
        if let v = double {
            return UInt(v)
        }
        return nil
    }

    public var string: String? {
        switch self {
        case .StringValue(let s): return s
        default: return nil
        }
    }

    public var array: [InterchangeData]? {
        switch self {
        case .ArrayValue(let array): return array
        default: return nil
        }
    }

    public var dictionary: [String: InterchangeData]? {
        switch self {
        case .ObjectValue(let dictionary): return dictionary
        default: return nil
        }
    }

    public subscript(index: UInt) -> InterchangeData? {
        set {
            switch self {
            case .ArrayValue(let a):
                var a = a
                if Int(index) < a.count {
                    if let json = newValue {
                        a[Int(index)] = json
                    } else {
                        a[Int(index)] = .NullValue
                    }
                    self = .ArrayValue(a)
                }
            default: break
            }
        }
        get {
            switch self {
            case .ArrayValue(let a):
                return Int(index) < a.count ? a[Int(index)] : nil
            default: return nil
            }
        }
    }

    public subscript(key: String) -> InterchangeData? {
        set {
            switch self {
            case .ObjectValue(let o):
                var o = o
                o[key] = newValue
                self = .ObjectValue(o)
            default: break
            }
        }
        get {
            switch self {
            case .ObjectValue(let o):
                return o[key]
            default: return nil
            }
        }
    }
}

extension InterchangeData: Equatable {}

public func ==(lhs: InterchangeData, rhs: InterchangeData) -> Bool {
    switch lhs {
    case .NullValue:
        switch rhs {
        case .NullValue: return true
        default: return false
        }
    case .BooleanValue(let lhsValue):
        switch rhs {
        case .BooleanValue(let rhsValue): return lhsValue == rhsValue
        default: return false
        }
    case .StringValue(let lhsValue):
        switch rhs {
        case .StringValue(let rhsValue): return lhsValue == rhsValue
        default: return false
        }
    case .NumberValue(let lhsValue):
        switch rhs {
        case .NumberValue(let rhsValue): return lhsValue == rhsValue
        default: return false
        }
    case .ArrayValue(let lhsValue):
        switch rhs {
        case .ArrayValue(let rhsValue): return lhsValue == rhsValue
        default: return false
        }
    case .ObjectValue(let lhsValue):
        switch rhs {
        case .ObjectValue(let rhsValue): return lhsValue == rhsValue
        default: return false
        }
    }
}

extension InterchangeData: NilLiteralConvertible {
    public init(nilLiteral value: Void) {
        self = .NullValue
    }
}

extension InterchangeData: BooleanLiteralConvertible {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .BooleanValue(value)
    }
}

extension InterchangeData: IntegerLiteralConvertible {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .NumberValue(Double(value))
    }
}

extension InterchangeData: FloatLiteralConvertible {
    public init(floatLiteral value: FloatLiteralType) {
        self = .NumberValue(Double(value))
    }
}

extension InterchangeData: StringLiteralConvertible {
    public typealias UnicodeScalarLiteralType = String

    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self = .StringValue(value)
    }

    public typealias ExtendedGraphemeClusterLiteralType = String

    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterType) {
        self = .StringValue(value)
    }

    public init(stringLiteral value: StringLiteralType) {
        self = .StringValue(value)
    }
}

extension InterchangeData: ArrayLiteralConvertible {
    public init(arrayLiteral elements: InterchangeData...) {
        self = .ArrayValue(elements)
    }
}

extension InterchangeData: DictionaryLiteralConvertible {
    public init(dictionaryLiteral elements: (String, InterchangeData)...) {
        var dictionary = [String: InterchangeData](minimumCapacity: elements.count)

        for pair in elements {
            dictionary[pair.0] = pair.1
        }
        
        self = .ObjectValue(dictionary)
    }
}

extension InterchangeData: CustomStringConvertible {
    public var description: String {
        var indentLevel = 0

        func serialize(data: InterchangeData) -> String {
            switch data {
            case .NullValue: return "null"
            case .BooleanValue(let b): return b ? "true" : "false"
            case .NumberValue(let n): return serializeNumber(n)
            case .StringValue(let s): return escapeAsJSONString(s)
            case .ArrayValue(let a): return serializeArray(a)
            case .ObjectValue(let o): return serializeObject(o)
            }
        }

        func serializeNumber(n: Double) -> String {
            if n == Double(Int64(n)) {
                return Int64(n).description
            } else {
                return n.description
            }
        }

        func serializeArray(a: [InterchangeData]) -> String {
            var s = "["
            indentLevel += 1

            for i in 0 ..< a.count {
                s += "\n"
                s += indent()
                s += serialize(a[i])

                if i != (a.count - 1) {
                    s += ","
                }
            }

            indentLevel -= 1
            return s + "\n" + indent() + "]"
        }

        func serializeObject(o: [String: InterchangeData]) -> String {
            var s = "{"
            indentLevel += 1
            var i = 0

            for (key, value) in o {
                s += "\n"
                s += indent()
                s += "\(escapeAsJSONString(key)): \(serialize(value))"

                if i != (o.count - 1) {
                    s += ","
                }
                i += 1
            }
            
            indentLevel -= 1
            return s + "\n" + indent() + "}"
        }
        
        func indent() -> String {
            var s = ""
            
            for _ in 0 ..< indentLevel {
                s += "    "
            }
            
            return s
        }

        return serialize(self)
    }
}
