// TCPSSLStreamServer.swift
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

//struct TCPSSLStreamServer: StreamServerType {
//    let port: Int
//    let context: SSLServerContext
//
//    init(port: Int, certificate: String, privateKey: String) throws {
//        self.port = port
//        self.context = try SSLServerContext(
//            certificate: certificate,
//            privateKey: privateKey
//        )
//    }
//
//    func accept(completion: (Void throws -> StreamType) -> Void) {
//        do {
//            let ip = try IP(port: 8080)
//            let serverSocket = try TCPServerSocket(ip: ip, backlog: 128)
//
//            while true {
//                let socket = try serverSocket.accept()
//                let stream = TCPStream(socket: socket)
//
//                let SSLStream = try SSLServerStream(context: context, rawStream: stream)
//                
//                co {
//                    completion {
//                        return SSLStream
//                    }
//                }
//            }
//        } catch {
//            completion {
//                throw error
//            }
//        }
//    }
//}
