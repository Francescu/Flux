// Base64.swift
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

private class Base64Encoder {

	enum Step { case A, B, C }

	static let paddingChar: UInt8 = 0x3D // =
	static let newlineChar: UInt8 = 0x0A // \n

	let chars: [UnicodeScalar]

	var step: Step = .A
	var result: UInt8 = 0

	var charsPerLine: Int?
	var stepcount: Int = 0

	let bytes: Data

	var offset = 0
	var output = Data()

	init(bytes: Data, charsPerLine: Int? = nil, specialChars: String? = nil) {
		self.charsPerLine = charsPerLine
		self.bytes = bytes
		self.chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".unicodeScalars) + Array((specialChars ?? "+/").unicodeScalars)
		guard bytes.count > 0 else { return }
		encodeBlock()
	}

	func encodeValue(value: UInt8) -> UInt8 {
		guard value <= 64 else { return Base64Encoder.paddingChar }
		return UInt8(chars[Int(value)].value)
	}

	func encodeBlock() {
		let fragment = bytes[offset]
		offset += 1

		switch step {
		case .A:
			result = (fragment & 0x0fc) >> 2
			output.appendByte(encodeValue(result))
			result = (fragment & 0x003) << 4
			step = .B
		case .B:
			result |= (fragment & 0x0f0) >> 4
			output.appendByte(encodeValue(result))
			result = (fragment & 0x00f) << 2
			step = .C
		case .C:
			result |= (fragment & 0x0c0) >> 6
			output.appendByte(encodeValue(result))
			result  = (fragment & 0x03f) >> 0
			output.appendByte(encodeValue(result))
			if let charsPerLine = self.charsPerLine {
				stepcount += 1
				if stepcount == charsPerLine/4 {
					output.appendByte(Base64Encoder.newlineChar)
					stepcount = 0
				}
			}
			step = .A
		}

		if offset < bytes.count {
			encodeBlock()
		} else {
			encodeBlockEnd()
		}
	}

	func encodeBlockEnd() {
		switch step {
		case .A:
			break
		case .B:
			output.appendByte(encodeValue(result))
			output.appendByte(Base64Encoder.paddingChar)
			output.appendByte(Base64Encoder.paddingChar)
		case .C:
			output.appendByte(encodeValue(result))
			output.appendByte(Base64Encoder.paddingChar)
		}
		if let _ = self.charsPerLine {
			output.appendByte(Base64Encoder.newlineChar)
		}
	}

}

private class Base64Decoder {

	enum Step { case A, B, C, D }

	static let decoding: [Int8] = [62, -1, -1, -1, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -2, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51]

	static func decodeValue(value: UInt8) -> Int8 {
		let tmp = Int(value - 43)
		guard tmp >= 0 && tmp < Base64Decoder.decoding.count else { return -1 }
		return Base64Decoder.decoding[tmp]
	}

	var step: Step = .A

	let bytes: Data
	var offset = 0

	var output: Data
	var outputOffset = 0

	init(data: Data) {
		self.bytes = data
        self.output = Data(count: data.count, repeatedValue: 0)
		guard data.count > 0 else { return }
		decodeBlock()
	}

	func decodeBlock() {
		var tmpFragment: Int8
		repeat {
			guard offset < bytes.count else { return }
			let byte = bytes[offset]
            offset += 1
			tmpFragment = Base64Decoder.decodeValue(byte)
		} while (tmpFragment < 0);
		let fragment = UInt8(bitPattern: tmpFragment)

		switch step {
		case .A:
			output[outputOffset]	 = (fragment & 0x03f) << 2
			step = .B
		case .B:
			output[outputOffset]	|= (fragment & 0x030) >> 4
            offset += 1
			output[outputOffset]	 = (fragment & 0x00f) << 4
			step = .C
		case .C:
			output[outputOffset]	|= (fragment & 0x03c) >> 2
            offset += 1
			output[outputOffset]	 = (fragment & 0x003) << 6
			step = .D
		case .D:
			output[outputOffset]	|= (fragment & 0x03f)
            offset += 1
			step = .A
		}

		decodeBlock()
	}

}

public final class Base64 {
	public static func encode(data: Data, charsPerLine: Int? = nil, specialChars: String? = nil) -> Data {
		return Base64Encoder(bytes: data, charsPerLine: charsPerLine, specialChars: specialChars).output
	}

	public static func decode(data: Data) -> Data {
		return Base64Decoder(data: data).output
	}
}
