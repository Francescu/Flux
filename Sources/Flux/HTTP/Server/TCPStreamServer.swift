// TCPStreamServer.swift
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

struct TCPStreamServer: StreamServerType {
    let port: Int
//    let processCount: Int

    func accept(completion: (Void throws -> StreamType) -> Void) {
        do {
            let ip = try IP(port: 8080)
            let serverSocket = try TCPServerSocket(ip: ip, backlog: 128)

//            forkProcesses()

            while true {
                let socket = try serverSocket.accept()
                co {
                    completion {
                        return TCPStream(socket: socket)
                    }
                }
            }
        } catch {
            completion {
                throw error
            }
        }
    }

//    private func forkProcesses() {
//        for i in 0 ..< processCount - 1 {
//            let pid = fork()
//
//            if pid < 0 {
//                // TODO: throw error
//                print("TCPServer: Only \(i + 1) of \(processCount) processes were created successfully.")
//            }
//
//            if pid > 0 { break }
//        }
//    }
}
