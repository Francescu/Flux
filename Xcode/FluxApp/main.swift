import Flux

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

//log.levels = [.Warning]
log.stream = try File(path: "/Users/paulofaria/hello.txt", mode: .AppendWrite)

let router = Router { route in
    route.get("/", middleware: logger) { request in
        return Response(status: .OK, body: "hello")
    }
}

Server(port: 8080, responder: router).start()
