// Regex.swift
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

struct RegexError: ErrorType {
    let description: String

    static func errorFromResult(result: Int32, preg: regex_t) -> RegexError {
        var preg = preg
        var buffer = [Int8](count: Int(BUFSIZ), repeatedValue: 0)
        regerror(result, &preg, &buffer, buffer.count)
        let description = String.fromCString(buffer)!
        return RegexError(description: description)
    }
}

public final class Regex {
    public struct RegexOptions: OptionSetType {
        public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }

        public static let Basic =            RegexOptions(rawValue: 0)
        public static let Extended =         RegexOptions(rawValue: 1)
        public static let CaseInsensitive =  RegexOptions(rawValue: 2)
        public static let ResultOnly =       RegexOptions(rawValue: 8)
        public static let NewLineSensitive = RegexOptions(rawValue: 4)
    }

    public struct MatchOptions: OptionSetType {
        public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }

        public static let FirstCharacterNotAtBeginningOfLine = MatchOptions(rawValue: REG_NOTBOL)
        public static let LastCharacterNotAtEndOfLine =        MatchOptions(rawValue: REG_NOTEOL)
    }

    var preg = regex_t()

    public init(pattern: String, options: RegexOptions = [.Extended]) throws {
        let result = regcomp(&preg, pattern, options.rawValue)

        if result != 0 {
            throw RegexError.errorFromResult(result, preg: preg)
        }
    }

    deinit {
        regfree(&preg)
    }

    public func matches(string: String, options: MatchOptions = []) -> Bool {
        var regexMatches = [regmatch_t](count: 1, repeatedValue: regmatch_t())
        let result = regexec(&preg, string, regexMatches.count, &regexMatches, options.rawValue)

        if result == 1 {
            return false
        }

        return true
    }

    public func groups(string: String, options: MatchOptions = []) -> [String] {
        var string = string
        let maxMatches = 10
        var groups = [String]()

        while true {
            var regexMatches = [regmatch_t](count: maxMatches, repeatedValue: regmatch_t())
            let result = regexec(&preg, string, regexMatches.count, &regexMatches, options.rawValue)

            if result == 1 {
                break
            }

            var j = 1

            while regexMatches[j].rm_so != -1 {
                let start = Int(regexMatches[j].rm_so)
                let end = Int(regexMatches[j].rm_eo)
                let match = string[string.startIndex.advancedBy(start) ..<  string.startIndex.advancedBy(end)]
                groups.append(match)
                j += 1
            }

            let offset = Int(regexMatches[0].rm_eo)
            if let offsetString = String(string.utf8[string.utf8.startIndex.advancedBy(offset) ..< string.utf8.endIndex]) {
                string = offsetString
            } else {
                break
            }
        }

        return groups
    }

    public func replace(string: String, withTemplate template: String, options: MatchOptions = []) -> String {
        var string = string
        let maxMatches = 10
        var totalReplacedString: String = ""

        while true {
            var regexMatches = [regmatch_t](count: maxMatches, repeatedValue: regmatch_t())
            let result = regexec(&preg, string, regexMatches.count, &regexMatches, options.rawValue)

            if result == 1 {
                break
            }

            let start = Int(regexMatches[0].rm_so)
            let end = Int(regexMatches[0].rm_eo)

            var replacedStringArray = Array<UInt8>(string.utf8)
            let templateArray = Array<UInt8>(template.utf8)
            replacedStringArray.replaceRange(start ..<  end, with: templateArray)

            guard let _replacedString = String(data: replacedStringArray) else {
                break
            }

            var replacedString = _replacedString

            let templateDelta = template.utf8.count - (end - start)
            let templateDeltaIndex = replacedString.utf8.startIndex.advancedBy(Int(end + templateDelta))

            replacedString = String(replacedString.utf8[replacedString.utf8.startIndex ..< templateDeltaIndex])

            totalReplacedString += replacedString
            string = String(string.utf8[string.utf8.startIndex.advancedBy(end) ..< string.utf8.endIndex])
        }
        
        return totalReplacedString + string
    }
}