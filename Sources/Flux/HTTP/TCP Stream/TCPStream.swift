// TCPStream.swift
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

public final class TCPStream: StreamType {
    private let socket: TCPClientSocket

    public init(socket: TCPClientSocket) {
        self.socket = socket
    }

    public var closed: Bool {
        return socket.closed
    }

    public func receive() throws -> Data {
        do {
            return try socket.receive(lowWaterMark: 1, highWaterMark: 4096)
        } catch TCPError.ConnectionResetByPeer(_, let data) {
            throw StreamError.ClosedStream(data: data)
        }
    }

    public func send(data: Data) throws {
        try assertNotClosed()
        try socket.send(data)
    }

    public func flush() throws {
        try assertNotClosed()
        try socket.flush()
    }

    public func close() -> Bool {
        return socket.close()
    }

    private func assertNotClosed() throws {
        if closed {
            throw StreamError.ClosedStream(data: nil)
        }
    }

}
