// WebSocket.swift
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

public class WebSocket {
    static let GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

	public enum WebSocketMode {
		case Server, Client
	}

	private enum State {
//		case HandshakeRequest, HandshakeResponse
		case Header, HeaderExtra, Payload
	}

	private enum CloseState {
		case Open
		case ServerClose
		case ClientClose
	}

	public enum WebSocketError: ErrorType {
		case NoFrame
	}

	public let mode: WebSocketMode = .Server
	private let stream: StreamType
	private var state: State = .Header
	private var closeState: CloseState = .Open

	private let queue = Channel<Data>(bufferSize: 10)

	private var initialFrame: WebSocketFrame?
	private var frames: [WebSocketFrame] = []
	private var buffer: Data = []

    private let binaryEventEmitter = EventEmitter<Data>()
    private let textEventEmitter = EventEmitter<String>()
    private let pingEventEmitter = EventEmitter<Data>()
    private let pongEventEmitter = EventEmitter<Data>()
    private let closeEventEmitter = EventEmitter<(code: Int?, reason: String?)>()

    public init(stream: StreamType) {
        self.stream = stream
    }

    public func onBinary(listen: EventListener<Data>.Listen) -> EventListener<Data> {
        return binaryEventEmitter.addListener(listen: listen)
    }

    public func onText(listen: EventListener<String>.Listen) -> EventListener<String> {
        return textEventEmitter.addListener(listen: listen)
    }

    public func onPing(listen: EventListener<Data>.Listen) -> EventListener<Data> {
        return pingEventEmitter.addListener(listen: listen)
    }

    public func onPong(listen: EventListener<Data>.Listen) -> EventListener<Data> {
        return pongEventEmitter.addListener(listen: listen)
    }

    public func onClose(listen: EventListener<(code: Int?, reason: String?)>.Listen) -> EventListener<(code: Int?, reason: String?)> {
        return closeEventEmitter.addListener(listen: listen)
    }

    public func send(string: String) throws {
        try send(.Text, data: string.data)
    }

    public func send(data: Data) throws {
        try send(.Binary, data: data)
    }

    public func send(convertible: DataConvertible) throws {
        try send(.Binary, data: convertible.data)
    }

    public func close(code: Int = 1000, reason: String? = nil) throws {
        if closeState == .ServerClose {
            return
        }

        if closeState == .Open {
            closeState = .ServerClose
        }

        var data = Data(UInt16(code).bytes())

        if let reason = reason {
            data += reason
        }

        try send(.Close, data: data)

        if closeState == .ClientClose {
            stream.close()
        }
    }

    public func ping(data: Data = []) throws {
        try send(.Ping, data: data)
    }

    public func ping(convertible: DataConvertible) throws {
        try send(.Ping, data: convertible.data)
    }
    
    public func pong(data: Data = []) throws {
        try send(.Pong, data: data)
    }

    public func pong(convertible: DataConvertible) throws {
        try send(.Pong, data: convertible.data)
    }

    func loop() throws {
        while !stream.closed {
            let data = try stream.receive()
            processData(data)
        }
    }

	private func processData(data: Data) {
        guard data.count > 0 else {
            return
        }

        var totalBytesRead = 0

        while totalBytesRead < data.count {
            let bytesRead = readBytes(Array(data[totalBytesRead ..< data.count]))

            if bytesRead < 0 {
                print("An unknown error occurred")
                break
            } else if bytesRead == 0 {
                break
            }

            totalBytesRead += bytesRead
        }
	}

	private func readBytes(data: [UInt8]) -> Int {
		guard data.count > 0 else { return -1 }

		let fail: String -> Int = { reason in
			print(reason)
			try! self.close(1002)
			return -1
		}

		switch state {
		case .Header:
			guard data.count >= 2 else { return -1 }

			let fin = data[0] & WebSocketFrame.FinMask != 0
			let rsv1 = data[0] & WebSocketFrame.Rsv1Mask != 0
			let rsv2 = data[0] & WebSocketFrame.Rsv2Mask != 0
			let rsv3 = data[0] & WebSocketFrame.Rsv3Mask != 0

			guard let opCode = WebSocketFrame.OpCode(rawValue: data[0] & WebSocketFrame.OpCodeMask) else { return fail("Invalid OpCode") }

			let masked = data[1] & WebSocketFrame.MaskMask != 0
			guard !masked || self.mode == .Server else { return fail("Frames must never be masked from server") }
			guard masked || self.mode == .Client else { return fail("Frames must always be masked from client") }

			let payloadLength = data[1] & WebSocketFrame.PayloadLenMask

			var headerExtraLength = masked ? sizeof(UInt32) : 0
			if payloadLength == 126 {
				headerExtraLength += sizeof(UInt16)
			} else if payloadLength == 127 {
				headerExtraLength += sizeof(UInt64)
			}

			if opCode.isControl {
				guard fin else { return fail("Control frames must be final") }
				guard !rsv1 && !rsv2 && !rsv3 else { return fail("Control frames must not use reserved bits") }
				guard payloadLength < 126 else { return fail("Control frame payload must have length < 126") }
			} else {
				guard opCode != .Continuation || frames.count != 0 else { return fail("Data continuation frames must follow an initial data frame") }
				guard opCode == .Continuation || frames.count == 0 else { return fail("Data frames must not follow an initial data frame unless continuations") }
//				guard !rsv1 || pmdEnabled else { return fail("Data frames must only use rsv1 bit if permessage-deflate extension is on") }
				guard !rsv2 && !rsv3 else { return fail("Data frames must never use rsv2 or rsv3 bits") }
			}

			var _opCode = opCode
			if !opCode.isControl && frames.count > 0 {
				initialFrame = frames.last
				_opCode = initialFrame!.opCode
			} else {
				self.buffer = []
			}

			frames.append(WebSocketFrame(fin: fin, rsv1: rsv1, rsv2: rsv2, rsv3: rsv3, opCode: _opCode, masked: masked, payloadLength: UInt64(payloadLength), headerExtraLength: headerExtraLength))

			if headerExtraLength > 0 {
				self.state = .HeaderExtra
			} else if payloadLength > 0 {
				self.state = .Payload
			} else {
				self.state = .Header
				do {
					try self.processFrames()
				} catch {
					return -1
				}
			}

			return 2
		case .HeaderExtra:
			guard let frame = frames.last where data.count >= frame.headerExtraLength else { return 0 }

			var payloadLength = UIntMax(frame.payloadLength)
			if payloadLength == 126 {
				payloadLength = data.toInt(size: 2)
			} else if payloadLength == 127 {
				payloadLength = data.toInt(size: 8)
			}

			self.frames.unsafeLast.payloadLength = payloadLength
			self.frames.unsafeLast.payloadRemainingLength = payloadLength

			if frame.masked {
				let maskOffset = max(Int(frame.headerExtraLength) - 4, 0)
				let maskKey = Array(data[maskOffset ..< maskOffset+4])
				guard maskKey.count == 4 else { return fail("maskKey wrong length") }
				self.frames.unsafeLast.maskKey = maskKey
			}

			if frame.payloadLength > 0 {
				state = .Payload
			} else {
				self.state = .Header
				do {
					try self.processFrames()
				} catch {
					return -1
				}
			}

			return frame.headerExtraLength
		case .Payload:
			guard let frame = frames.last where data.count > 0 else { return 0 }

			let consumeLength = min(frame.payloadRemainingLength, UInt64(data.count))

			var _data: [UInt8]
			if self.mode == .Server {
				guard let maskKey = frame.maskKey else { return -1 }
				_data = []
				for byte in data[0..<Int(consumeLength)] {
					_data.append(byte ^ maskKey[self.frames.unsafeLast.maskOffset % 4])
					self.frames.unsafeLast.maskOffset += 1
				}
			} else {
				_data = data
			}

			buffer += _data

			let newPayloadRemainingLength = frame.payloadRemainingLength - consumeLength
			self.frames.unsafeLast.payloadRemainingLength = newPayloadRemainingLength

			if newPayloadRemainingLength == 0 {
				self.state = .Header
				do {
					try self.processFrames()
				} catch {
					return -1
				}
			}

			return Int(consumeLength)
		}
	}

	private func processFrames() throws {
		guard let frame = frames.last else {
            throw WebSocketError.NoFrame
        }

		guard frame.fin else {
            return
        }

		let buffer = self.buffer

		self.frames.removeAll()
		self.buffer.removeAllBytes()
		self.initialFrame = nil

		switch frame.opCode {
		case .Binary:
			binaryEventEmitter.emit(buffer)
		case .Text:
			textEventEmitter.emit(String.fromData(buffer))
		case .Ping:
			pingEventEmitter.emit(buffer)
		case .Pong:
			pongEventEmitter.emit(buffer)
		case .Close:
			if self.closeState == .Open {
				var closeCode: Int?
				var closeReason: String?
				var data = buffer
                
				if data.count >= 2 {
					closeCode = Int(UInt16(data.prefix(2).toInt(size: 2)))
					data.removeFirst(2)

					if data.count > 0 {
                        closeReason = String.fromData(data)
                    }
				}

				closeState = .ClientClose
				try close(closeCode ?? 1000, reason: closeReason)

				closeEventEmitter.emit((closeCode, closeReason))

			} else if self.closeState == .ServerClose {
				stream.close()
			}
		case .Continuation:
			return
		}
	}

	private func send(opCode: WebSocketFrame.OpCode, data: Data) throws {
		let frame = WebSocketFrame(opCode: opCode, data: data)
		let data = frame.getData()
		try stream.send(data)
    }

    static func accept(key: String) -> String? {
        return try? String(data: Base64.encode(Data(SHA1.bytes(key + WebSocket.GUID))))
    }
}
