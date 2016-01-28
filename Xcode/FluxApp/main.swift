import Flux

let router = Router(middleware: logger) { route in
    route.get("/") { request in
        return Response(status: .OK, body: "hello")
    }

    route.get("/yoo") { request in
        return Response(status: .OK, body: "yoo")
    }
}

let webSocketServer = WebSocketServer { webSocket in
    log.info("WebSocket connect:")

    webSocket.onBinary { data in
        log.info("WebSocket binary: \(data)")
        try! webSocket.send(data)
    }

    webSocket.onText { text in
        log.info("WebSocket text: \(text)")
        try! webSocket.send(text)
    }

    webSocket.onPing { data in
        log.info("WebSocket ping: \(data)")
        try! webSocket.pong(data)
    }

    webSocket.onPong { data in
        log.info("WebSocket pong: \(data)")
    }

    webSocket.onClose { code, reason in
        log.info("WebSocket close: \(code) \(reason)")
    }
}

let certificate = "/Users/paulofaria/server.crt"
let privateKey = "/Users/paulofaria/server.key"
let certificateChain = "/Users/paulofaria/rootCA.crt"

try Server(port: 8080, responder: router).startInBackground()
try Server(port: 8081, certificate: certificate, privateKey: privateKey, certificateChain: certificateChain, responder: router).startInBackground()
try Server(port: 8082, responder: webSocketServer).startInBackground()
try Server(port: 8083, certificate: certificate, privateKey: privateKey, certificateChain: certificateChain, responder: webSocketServer).start()
