import XCTest
import Flux

class HTTPTests: XCTestCase {
    func testRouter() {
        do {

            func isFooBar(request: Request) -> Bool {
                return request.query["foo"] == "bar"
            }

            let router = Router { route in
                route.get("/", middleware: branch(isFooBar, yes: [logger])) { request in
                    return Response(status: .OK, body: "hello")
                }
            }

            Server(port: 8080, responder: router).start()
        } catch {
            print(error)
        }
    }

    func testSSL() {
        do {
        let router = Router(middleware: logger) { route in
            route.get("/") { request in
                return Response(status: .OK, body: "hello")
            }
        }
        
        try Server(port: 8080, certificate: "/Users/paulofaria/csr.pem", privateKey: "/Users/paulofaria/key.pem", responder: router).start()
        } catch {
            print(error)
        }
    }

    func testUDP() {
        do {
            let listenIP = try IP(port: 40000)
            let socket = try UDPSocket(ip: listenIP)
            let (data, ip) = try socket.receive(length: 256)
            print(try? String(data: data))
            print(ip)
        } catch {
            print(error)
        }
    }
}
