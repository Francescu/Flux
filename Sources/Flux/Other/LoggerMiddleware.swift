// LoggerMiddleware.swift
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

public let logger = LoggerMiddleware()

public struct LoggerMiddleware: MiddlewareType {
    public init() {}

    public func respond(request: Request, chain: ChainType) throws -> Response {
        let response = try chain.proceed(request)
        log("========================================\n")
        log("Request:\n")
        log("\(request)\n")
        log("----------------------------------------\n")
        log("Response:\n")
        log("\(response)\n")
        log("========================================\n\n")
        return response
    }

    private func log(string: String) {
        write(STDOUT_FILENO, string, string.utf8.count)
    }
}

public let debugLogger = DebugLoggerMiddleware()

public struct DebugLoggerMiddleware: MiddlewareType {
    public init() {}

    public func respond(request: Request, chain: ChainType) throws -> Response {
        let response = try chain.proceed(request)
        log("========================================\n")
        log("Request:\n")
        log("\(request.debugDescription)\n")
        log("----------------------------------------\n")
        log("Response:\n")
        log("\(response.debugDescription)\n")
        log("========================================\n\n")
        return response
    }

    private func log(string: String) {
        write(STDOUT_FILENO, string, string.utf8.count)
    }
}