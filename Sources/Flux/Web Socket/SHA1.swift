//
//  SHA1.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 16/08/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

private func rotateLeft(v:UInt32, _ n:UInt32) -> UInt32 {
	return ((v << n) & 0xFFFFFFFF) | (v >> (32 - n))
}

private func toUInt32Array(slice: ArraySlice<UInt8>) -> Array<UInt32> {
	var result = Array<UInt32>()
	result.reserveCapacity(16)
	for idx in slice.startIndex.stride(to: slice.endIndex, by: sizeof(UInt32)) {
		let a = UInt32(slice[idx])
		let b = UInt32(slice[idx.advancedBy(1)])
		let c = UInt32(slice[idx.advancedBy(2)])
		let d = UInt32(slice[idx.advancedBy(3)])
		let val:UInt32 = (d << 24) | (c << 16) | (b << 8) | a
		result.append(val)
	}
	return result
}

private struct BytesSequence: SequenceType {
	let chunkSize: Int
	let data: [UInt8]

	func generate() -> AnyGenerator<ArraySlice<UInt8>> {

		var offset:Int = 0

		return AnyGenerator {
			let end = min(self.chunkSize, self.data.count - offset)
			let result = self.data[offset..<offset + end]
			offset += result.count
			return result.count > 0 ? result : nil
		}
	}
}

private extension Int {
	func bytes(totalBytes: Int = sizeof(Int)) -> [UInt8] {
		var totalBytes = totalBytes
		let valuePointer = UnsafeMutablePointer<Int>.alloc(1)
		valuePointer.memory = self
		let bytesPointer = UnsafeMutablePointer<UInt8>(valuePointer)
		var bytes = [UInt8](count: totalBytes, repeatedValue: 0)
		let size = sizeof(Int)
		if totalBytes > size { totalBytes = size }
		for j in 0 ..< totalBytes {
			bytes[totalBytes - 1 - j] = (bytesPointer + j).memory
		}
		valuePointer.destroy()
		valuePointer.dealloc(1)
		return bytes
	}
}

internal class SHA1 {
	private static let size:Int = 20 // 160 / 8
	private static let h:[UInt32] = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0]

	internal static func bytes(string: String) -> [UInt8] {
		let data = string.utf8.lazy.map({ $0 as UInt8 }) as [UInt8]
		return self.calculate(data)
	}

	internal static func hex(string: String) -> String? {
		let bytes = self.bytes(string)
		return bytes.hexString
	}

	private static func calculate(message: [UInt8]) -> [UInt8] {
		let len = 64
		var tmpMessage = message

		// Step 1. Append Padding Bits
		tmpMessage.append(0x80) // append one bit (UInt8 with one bit) to message

		// append "0" bit until message length in bits ≡ 448 (mod 512)
		var msgLength = tmpMessage.count
		var counter = 0

		while msgLength % len != (len - 8) {
			counter += 1
			msgLength += 1
		}

		tmpMessage += Array<UInt8>(count: counter, repeatedValue: 0)

		// -----

		// hash values
		var hh = SHA1.h

		// append message length, in a 64-bit big-endian integer. So now the message length is a multiple of 512 bits.
		tmpMessage += (message.count * 8).bytes(64 / 8)

		// Process the message in successive 512-bit chunks:
		let chunkSizeBytes = 512 / 8 // 64
		for chunk in BytesSequence(chunkSize: chunkSizeBytes, data: tmpMessage) {
			// break chunk into sixteen 32-bit words M[j], 0 ≤ j ≤ 15, big-endian
			// Extend the sixteen 32-bit words into eighty 32-bit words:
			var M:[UInt32] = [UInt32](count: 80, repeatedValue: 0)
			for x in 0..<M.count {
				switch (x) {
				case 0...15:
					let start = chunk.startIndex + (x * sizeofValue(M[x]))
					let end = start + sizeofValue(M[x])
					let le = toUInt32Array(chunk[start..<end])[0]
					M[x] = le.bigEndian
					break
				default:
					M[x] = rotateLeft(M[x-3] ^ M[x-8] ^ M[x-14] ^ M[x-16], 1) //FIXME: n:
					break
				}
			}

			var A = hh[0]
			var B = hh[1]
			var C = hh[2]
			var D = hh[3]
			var E = hh[4]

			// Main loop
			for j in 0...79 {
				var f: UInt32 = 0;
				var k: UInt32 = 0

				switch (j) {
				case 0...19:
					f = (B & C) | ((~B) & D)
					k = 0x5A827999
					break
				case 20...39:
					f = B ^ C ^ D
					k = 0x6ED9EBA1
					break
				case 40...59:
					f = (B & C) | (B & D) | (C & D)
					k = 0x8F1BBCDC
					break
				case 60...79:
					f = B ^ C ^ D
					k = 0xCA62C1D6
					break
				default:
					break
				}

				let temp = (rotateLeft(A,5) &+ f &+ E &+ M[j] &+ k) & 0xffffffff
				E = D
				D = C
				C = rotateLeft(B, 30)
				B = A
				A = temp
			}

			hh[0] = (hh[0] &+ A) & 0xffffffff
			hh[1] = (hh[1] &+ B) & 0xffffffff
			hh[2] = (hh[2] &+ C) & 0xffffffff
			hh[3] = (hh[3] &+ D) & 0xffffffff
			hh[4] = (hh[4] &+ E) & 0xffffffff
		}

		// Produce the final hash value (big-endian) as a 160 bit number:
		var result = [UInt8]()
		result.reserveCapacity(hh.count / 4)
		hh.forEach {
			let item = $0.bigEndian
			result += [UInt8(item & 0xff), UInt8((item >> 8) & 0xff), UInt8((item >> 16) & 0xff), UInt8((item >> 24) & 0xff)]
		}
		return result
	}
}
