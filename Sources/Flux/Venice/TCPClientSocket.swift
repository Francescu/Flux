// TCPClientSocket.swift
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

import CLibvenice

public final class TCPClientSocket: TCPSocket {
    override init(socket: tcpsock) throws {
        try super.init(socket: socket)
    }

    public init(ip: IP, deadline: Deadline = noDeadline) throws {
        try super.init(socket: tcpconnect(ip.address, deadline))
    }

    public init(fileDescriptor: FileDescriptor) throws {
        try super.init(socket: tcpattach(fileDescriptor, 0))
    }

    public func send(data: Data, deadline: Deadline = noDeadline) throws {
        try assertNotClosed()

        let bytesProcessed = data.withUnsafeBufferPointer {
            tcpsend(socket, $0.baseAddress, $0.count, deadline)
        }

        try TCPError.assertNoSendErrorWithData(data, bytesProcessed: bytesProcessed)
    }

    public func flush(deadline: Deadline = noDeadline) throws {
        try assertNotClosed()

        tcpflush(socket, deadline)

        try TCPError.assertNoError()
    }

    public func receive(bufferSize bufferSize: Int = 256, deadline: Deadline = noDeadline) throws -> Data {
        try assertNotClosed()

        var data = Data.bufferWithSize(bufferSize)
        let bytesProcessed = data.withUnsafeMutableBufferPointer {
            tcprecv(socket, $0.baseAddress, $0.count, deadline)
        }

        try TCPError.assertNoReceiveErrorWithData(data, bytesProcessed: bytesProcessed)
        return processedDataFromSource(data, bytesProcessed: bytesProcessed)
    }

    public func receiveWithLowWaterMark(lowWaterMark: Int = 1, highWaterMark: Int = 256, deadline: Deadline = noDeadline) throws -> Data {
        try assertNotClosed()

        var data = Data.bufferWithSize(highWaterMark)
        let bytesProcessed = data.withUnsafeMutableBufferPointer {
            tcprecvlh(socket, $0.baseAddress, lowWaterMark, highWaterMark, deadline)
        }

        try TCPError.assertNoReceiveErrorWithData(data, bytesProcessed: bytesProcessed)
        return processedDataFromSource(data, bytesProcessed: bytesProcessed)
    }

    public func receive(bufferSize bufferSize: Int = 256, untilDelimiter delimiter: String, deadline: Deadline = noDeadline) throws -> Data {
        try assertNotClosed()

        var data = Data.bufferWithSize(bufferSize)
        let bytesProcessed = data.withUnsafeMutableBufferPointer {
            tcprecvuntil(socket, $0.baseAddress, $0.count, delimiter, delimiter.utf8.count, deadline)
        }
        
        try TCPError.assertNoReceiveErrorWithData(data, bytesProcessed: bytesProcessed)
        return processedDataFromSource(data, bytesProcessed: bytesProcessed)
    }

    public func attach(fileDescriptor: FileDescriptor) throws {
        try super.attach(fileDescriptor, isServer: false)
    }
}

extension TCPClientSocket {
    public func send(convertible: DataConvertible, deadline: Deadline = noDeadline) throws {
        try send(convertible.data, deadline: deadline)
    }

    public func receiveString(bufferSize bufferSize: Int = 256, deadline: Deadline = noDeadline) throws -> String {
        let result = try receive(bufferSize: bufferSize, deadline: deadline)
        return try String(data: result)
    }

    public func receiveString(bufferSize bufferSize: Int = 256, untilDelimiter delimiter: String, deadline: Deadline = noDeadline) throws -> String {
        let result = try receive(bufferSize: bufferSize, untilDelimiter: delimiter, deadline: deadline)
        return try String(data: result)
    }
}

//extension String {
//    init(data: Data) throws {
//        struct Error: ErrorType {}
//        var string = ""
//        var decoder = UTF8()
//        var generator = data.generate()
//        var finished = false
//
//        while !finished {
//            let decodingResult = decoder.decode(&generator)
//            switch decodingResult {
//            case .Result(let char): string.append(char)
//            case .EmptyInput: finished = true
//            case .Error:
//                throw Error()
//            }
//        }
//
//        self.init(string)
//    }
//}