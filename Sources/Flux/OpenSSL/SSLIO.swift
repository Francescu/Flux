// SSLIO.swift
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

public class SSLIO {
    public enum Method {
		case Memory

        var method: UnsafeMutablePointer<BIO_METHOD> {
            switch self {
            case .Memory:
                return BIO_s_mem()
            }
        }
	}

    enum SSLIOError: ErrorType {
        case BIO(description: String)
        case UnsupportedMethod(description: String)
    }

    var bio: UnsafeMutablePointer<BIO>

	public init(method: Method) throws {
		OpenSSL.initialize()
		bio = BIO_new(method.method)

        if bio == nil {
            throw SSLIOError.BIO(description: lastSSLErrorDescription)
        }
	}

	public func write(data: Data) throws {
		var data = data
        let result = BIO_write(bio, &data, Int32(data.count))

        if result == -2 {
            throw SSLIOError.UnsupportedMethod(description: lastSSLErrorDescription)
        }
	}

	public func read() throws -> Data {
		var buffer: [UInt8] = Array(count: DEFAULT_BUFFER_SIZE, repeatedValue: 0)

        let result = BIO_read(bio, &buffer, Int32(buffer.count))

        if result == -2 {
            throw SSLIOError.UnsupportedMethod(description: lastSSLErrorDescription)
        }

		if result > 0 {
            return Data(bytes: Array(buffer.prefix(Int(result))))
		} else {
            return Data()
		}
	}

}
