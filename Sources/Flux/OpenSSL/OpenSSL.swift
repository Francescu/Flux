// OpenSSL.swift
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

#if os(Linux)
	import Glibc
#else
	import Darwin.C
#endif

import COpenSSL

public let DEFAULT_BUFFER_SIZE = 4096

public final class OpenSSL: SSLType {

	private static var _initialize: Void = {
        print("called once")
	    SSL_library_init()
	    SSL_load_error_strings()
	    ERR_load_crypto_strings()
	    OPENSSL_config(nil)
	}()

	public static func initialize() {
	    let _ = self._initialize
	}

}

public func SSL_CTX_set_options(ctx: UnsafeMutablePointer<SSL_CTX>, _ op: Int) -> Int {
	return SSL_CTX_ctrl(ctx, SSL_CTRL_OPTIONS, op, nil)
}

private let SSL_CTRL_SET_ECDH_AUTO: Int32 = 94

public func SSL_CTX_set_ecdh_auto(ctx: UnsafeMutablePointer<SSL_CTX>, _ onoff: Int) -> Int {
	return SSL_CTX_ctrl(ctx, SSL_CTRL_SET_ECDH_AUTO, onoff, nil)
}
