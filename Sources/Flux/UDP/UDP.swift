// TCPServerSocket.swift
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
import CLibvenice

public final class UDPSocket {
    private var socket: udpsock

    public var port: Int {
        return Int(udpport(self.socket))
    }

    public private(set) var closed = false

    public init(ip: IP) throws {
        self.socket = udplisten(ip.address)

        if errno != 0 {
            closed = true
            throw TCPError.lastError
        }
    }

    public init(fileDescriptor: Int32) throws {
        self.socket = udpattach(fileDescriptor)

        if errno != 0 {
            closed = true
            throw TCPError.lastError
        }
    }

    deinit {
        close()
    }

    public func send(ip ip: IP, data: [UInt8], deadline: Deadline = noDeadline) throws {
        if closed {
            throw TCPError.closedSocketError
        }

        var data = data
        udpsend(socket, ip.address, &data, data.count)

        if errno != 0 {
            throw TCPError.lastErrorWithData(data, bytesProcessed: 0, receive: false)
        }
    }

    public func receive(bufferSize: Int = 256, deadline: Deadline = noDeadline) throws -> ([UInt8], IP) {
        if closed {
            throw TCPError.closedSocketError
        }

        var data: [UInt8] = [UInt8](count: bufferSize, repeatedValue: 0)

        var address = ipaddr()
        let bytesProcessed = udprecv(socket, &address, &data, data.count, deadline)

        if errno != 0 {
            throw TCPError.lastErrorWithData(data, bytesProcessed: bytesProcessed, receive: true)
        }

        let processedData = processedDataFromSource(data, bytesProcessed: bytesProcessed)
        let ip = IP(address: address)

        return (processedData, ip)
    }

    public func attach(fileDescriptor: Int32) throws {
        if !closed {
            udpclose(socket)
        }

        socket = udpattach(fileDescriptor)
        closed = false

        if errno != 0 {
            closed = true
            throw TCPError.lastError
        }
    }

    public func detach() throws -> Int32 {
        if closed {
            throw TCPError.closedSocketError
        }

        closed = true
        return udpdetach(socket)
    }

    public func close() {
        if !closed {
            closed = true
            udpclose(socket)
        }
    }
}