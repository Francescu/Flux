// SSLSession.swift
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

public class SSLSession {
	public enum State: Int32 {
		case Connect		= 0x1000
		case Accept			= 0x2000
		case Mask			= 0x0FFF
		case Init			= 0x3000
		case Before			= 0x4000
		case OK				= 0x03
		case Renegotiate	= 0x3004
		case Error			= 0x05
	}

    var ssl: UnsafeMutablePointer<SSL>

	public init(context: SSLContext) {
		OpenSSL.initialize()

        ssl = SSL_new(context.context)

        if ssl == nil {
            print("fuck")
        }
	}

	deinit {
		shutdown()
	}

	public var state: State {
		let stateNumber = SSL_state(ssl)
        let desc = String.fromCString(SSL_state_string(ssl))!
        print(desc)
        let state = State(rawValue: stateNumber)
		return state ?? .Error
	}

	public var peerCertificate: SSLCertificate? {
		let certificate = SSL_get_peer_certificate(ssl)

        guard certificate != nil else {
            return nil
        }

        defer {
            X509_free(certificate)
        }

		return SSLCertificate(certificate: certificate)
	}

	public func setIO(readIO readIO: SSLIO, writeIO: SSLIO) {
        SSL_set_bio(ssl, readIO.bio, writeIO.bio)
	}

	public func doHandshake() {
		SSL_do_handshake(ssl)
        print(state)
	}

	public func write(data: [UInt8]) {
		var data = data
		SSL_write(ssl, &data, Int32(data.count))
	}

	public func read() -> [UInt8] {
		var buffer: [UInt8] = Array(count: DEFAULT_BUFFER_SIZE, repeatedValue: 0)

		let readSize = SSL_read(ssl, &buffer, Int32(buffer.count))

        if readSize > 0 {
			return Array(buffer.prefix(Int(readSize)))
		} else {
			return []
		}
	}

	public func shutdown() {
		SSL_shutdown(ssl)
	}
}
