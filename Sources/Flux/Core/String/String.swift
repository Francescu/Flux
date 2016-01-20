// String.swift
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

extension String {
    public init(URLEncodedString: String) throws {
        let spaceCharacter: UInt8 = 32
        let percentCharacter: UInt8 = 37
        let plusCharacter: UInt8 = 43

        var encodedBytes: [UInt8] = [] + URLEncodedString.utf8
        var decodedBytes: [UInt8] = []
        var i = 0

        while i < encodedBytes.count {
            let currentCharacter = encodedBytes[i]

            switch currentCharacter {
            case percentCharacter:
                let unicodeA = UnicodeScalar(encodedBytes[i + 1])
                let unicodeB = UnicodeScalar(encodedBytes[i + 2])

                let hexString = "\(unicodeA)\(unicodeB)"

                let character = try Int(hexString: hexString)

                decodedBytes.append(UInt8(character))
                i += 3

            case plusCharacter:
                decodedBytes.append(spaceCharacter)
                i += 1

            default:
                decodedBytes.append(currentCharacter)
                i += 1
            }
        }

        try self.init(data: Data(bytes: decodedBytes))
    }


    public init(data: Data) throws {
        struct Error: ErrorType {}
        var string = ""
        var decoder = UTF8()
        var generator = data.generate()
        var finished = false
        
        while !finished {
            let decodingResult = decoder.decode(&generator)
            switch decodingResult {
            case .Result(let char): string.append(char)
            case .EmptyInput: finished = true
            case .Error:
                throw Error()
            }
        }
        
        self.init(string)
    }

    public func splitBy(separator: Character, allowEmptySlices: Bool = false) -> [String] {
        return characters.split(allowEmptySlices: allowEmptySlices) { $0 == separator }.map { String($0) }
    }

    public func trim() -> String {
        return stringByTrimmingCharactersInSet(CharacterSet.whitespaceAndNewline)
    }

    public func stringByTrimmingCharactersInSet(characterSet: Set<Character>) -> String {
        let string = stringByTrimmingFromStartCharactersInSet(characterSet)
        return string.stringByTrimmingFromEndCharactersInSet(characterSet)
    }

    public func stringByTrimmingFromStartCharactersInSet(characterSet: Set<Character>) -> String {
        var trimStartIndex: Int = characters.count

        for (index, character) in characters.enumerate() {
            if !characterSet.contains(character) {
                trimStartIndex = index
                break
            }
        }

        return self[startIndex.advancedBy(trimStartIndex) ..< endIndex]
    }

    public func stringByTrimmingFromEndCharactersInSet(characterSet: Set<Character>) -> String {
        var endIndex: Int = characters.count

        for (index, character) in characters.reverse().enumerate() {
            if !characterSet.contains(character) {
                endIndex = index
                break
            }
        }

        return self[startIndex ..< startIndex.advancedBy(characters.count - endIndex)]
    }

    public func dropFirstCharacters(n: Int) -> String {
        return self.characters.dropFirst(n).map({String($0)}).joinWithSeparator("")
    }
}

public struct CharacterSet {
    public static var whitespaceAndNewline: Set<Character> {
        return [" ", "\n"]
    }
}

extension String: DataConvertible {
    public var data: Data {
        return Data(bytes: [Byte](utf8))
    }
}