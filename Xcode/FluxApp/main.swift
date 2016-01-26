import Flux

let middleware = chain(logger, contentNegotiator)

let router = Router(matcher: RegexRouteMatcher.self) { route in
    route.get("/") { request in
        return Response(status: .OK, body: "hello")
    }
}

try Server(port: 8080, responder: router).startInBackground()
try Server(port: 8081, responder: router).start()
