// SSLClientStream.swift
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
// IMPLIED, INCLUDINbG BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import COpenSSL

public final class SSLClientStream: StreamType {
    private let context: SSLClientContext
    private let rawStream: StreamType
    private let ssl: SSLSession
    private let readIO: SSLIO
    private let writeIO: SSLIO

    public var closed: Bool = false

	public init(context: SSLClientContext, rawStream: StreamType) throws {
		OpenSSL.initialize()

		self.context = context
		self.rawStream = rawStream

		readIO = try SSLIO(method: .Memory)
		writeIO = try SSLIO(method: .Memory)

        ssl = try SSLSession(context: context)
		ssl.setIO(readIO: readIO, writeIO: writeIO)

        ssl.setConnectState()
	}

    public func receive() throws -> Data {
        let data = try rawStream.receive()
        try readIO.write(data)

        var decriptedData = Data()

        while true {
            do {
                decriptedData += try ssl.read()
            } catch SSLSessionError.WantRead {
                if decriptedData.count > 0 {
                    return decriptedData
                }
                let data = try rawStream.receive()
                try readIO.write(data)
            } catch SSLSessionError.ZeroReturn {
                return decriptedData
            }
        }
    }

    public func send(data: Data) throws {
        while !ssl.initializationFinished {
            do {
                try ssl.handshake()
            } catch SSLSessionError.WantRead {
            }
            do {
                try send()
            } catch SSLIOError.ShouldRetry {
                if ssl.initializationFinished {
                    break
                }
            }
            try rawStream.flush()
            let data = try rawStream.receive()
            try readIO.write(data)
        }

        if data.count > 0 {
            ssl.write(data)
            do {
                try send()
            } catch SSLIOError.ShouldRetry {}
        } else {
            try rawStream.send(data)
        }
    }

    public func flush() throws {
        try rawStream.flush()
    }

    public func close() -> Bool {
        return rawStream.close()
    }

    private func send() throws {
        let data = try writeIO.read()
        try rawStream.send(data)
    }
}
