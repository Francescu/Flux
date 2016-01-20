// SSLServerStream.swift
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

public final class SSLServerStream: StreamType {
	private let rawStream: StreamType
	private let context: SSLServerContext
	private let ssl: SSLSession
	private let readIO = try! SSLIO(method: .Memory)
	private let writeIO = try! SSLIO(method: .Memory)

	public init(context: SSLServerContext, rawStream: StreamType) throws {		
		OpenSSL.initialize()

        self.rawStream = rawStream
		self.context = context

		ssl = SSLSession(context: context)
		ssl.setIO(readIO: readIO, writeIO: writeIO)
		SSL_set_accept_state(ssl.ssl)
	}

	public func receive(completion: (Void throws -> Data) -> Void) {
		rawStream.receive { getData in
			do {
				let data = try getData()

				guard data.count > 0 else {
                    return
                }

				try self.readIO.write(data.bytes)

                while self.ssl.state != .OK {
                    self.ssl.doHandshake()
                    try self.checkSSLOutput()
                    try self.readIO.write(data.bytes)
                }

                let aData = self.ssl.read()
                
                if aData.count > 0 {
                    completion {
                        return Data(bytes: aData)
                    }
                }
			} catch {
				completion {
                    throw error
                }
			}
		}
	}

	public func send(data: Data) throws {
		ssl.write(data.bytes)
		try checkSSLOutput()
	}

    public func flush() throws {
        try rawStream.flush()
    }

	public func close() {
		rawStream.close()
	}

	private func checkSSLOutput() throws {
		let bytes = try writeIO.read()

		guard bytes.count > 0 else {
            return
        }

		try rawStream.send(Data(bytes: bytes))
	}
}
