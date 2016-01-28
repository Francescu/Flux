// WebSocketsServer.swift
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

public struct WebSocketServer: ResponderType {
	private let onConnect: WebSocket -> Void

	public init(onConnect: WebSocket -> Void) {
		self.onConnect =  onConnect
	}

	public func respond(request: Request) throws -> Response {
		guard request.isWebSocket else {
			return Response(status: .BadRequest)
		}

		guard let key = request.webSocketKey else {
			return Response(status: .BadRequest)
		}

        guard let accept = WebSocket.accept(key) else {
			return Response(status: .InternalServerError)
		}
		
		let headers = [
			"Connection": "Upgrade",
			"Upgrade": "websocket",
			"Sec-WebSocket-Accept": accept
		]

		return Response(status: .SwitchingProtocols, headers: headers) { stream in
            let webSocket = WebSocket(stream: stream)
            self.onConnect(webSocket)
            try webSocket.loop()
		}
    }
}

public extension Request {
    public var webSocketVersion: String? {
        return getHeader("Sec-Websocket-Version")?.lowercaseString
    }

    public var webSocketKey: String? {
        return getHeader("Sec-Websocket-Key")
    }

    public var isWebSocket: Bool {
        return connection == "upgrade" &&
                upgrade == "websocket" &&
                webSocketVersion == "13" &&
                webSocketKey != nil
    }
}
