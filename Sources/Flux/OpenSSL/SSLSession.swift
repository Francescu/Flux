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

public enum SSLSessionError: ErrorType {
    case Session(description: String)
    case WantRead(description: String)
    case WantWrite(description: String)
    case ZeroReturn(description: String)
}

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
        case Unknown        = -1
	}

    var ssl: UnsafeMutablePointer<SSL>

	public init(context: SSLContext) throws {
		OpenSSL.initialize()

        ssl = SSL_new(context.context)

        if ssl == nil {
            throw SSLSessionError.Session(description: lastSSLErrorDescription)
        }
	}

	deinit {
		shutdown()
	}

    public func setAcceptState() {
        SSL_set_accept_state(ssl)
    }

    public func setConnectState() {
        SSL_set_connect_state(ssl)
    }

    public var stateDescription: String {
        return String.fromCString(SSL_state_string_long(ssl))!
    }

	public var state: State {
		let stateNumber = SSL_state(ssl)
        let state = State(rawValue: stateNumber)
		return state ?? .Unknown
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

    var initializationFinished: Bool {
        return SSL_state(ssl) == SSL_ST_OK
    }

	public func handshake() throws {
        let result = SSL_do_handshake(ssl)

        if result <= 0 {
            switch SSL_get_error(ssl, result) {
            case SSL_ERROR_WANT_READ:
                throw SSLSessionError.WantRead(description: lastSSLErrorDescription)
            case SSL_ERROR_WANT_WRITE:
                throw SSLSessionError.WantWrite(description: lastSSLErrorDescription)
            default:
                throw SSLSessionError.Session(description: lastSSLErrorDescription)
            }
        }
	}

	public func write(data: Data) {
        data.withUnsafeBufferPointer {
            SSL_write(ssl, $0.baseAddress, Int32($0.count))
        }
	}

	public func read() throws -> Data {
		var data = Data.bufferWithSize(DEFAULT_BUFFER_SIZE)

        let result = data.withUnsafeMutableBufferPointer {
            SSL_read(ssl, $0.baseAddress, Int32($0.count))
        }

        if result <= 0 {
            let error = SSL_get_error(ssl, result)
            switch error {
            case SSL_ERROR_WANT_READ:
                throw SSLSessionError.WantRead(description: lastSSLErrorDescription)
            case SSL_ERROR_WANT_WRITE:
                throw SSLSessionError.WantWrite(description: lastSSLErrorDescription)
            case SSL_ERROR_ZERO_RETURN:
                throw SSLSessionError.ZeroReturn(description: lastSSLErrorDescription)
            default:
                throw SSLSessionError.Session(description: lastSSLErrorDescription)
            }
        }

        return data.prefix(Int(result))
	}

	public func shutdown() {
		SSL_shutdown(ssl)
	}
}
