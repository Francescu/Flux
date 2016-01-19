import XCTest
import Flux

class HTTPTests: XCTestCase {
//    func test() {
//        do {
//        let router = Router(middleware: logger) { route in
//            route.get("/") { request in
//                return Response(status: .OK, body: "hello")
//            }
//        }
//        
//        try Server(port: 8080, certificate: "/Users/paulofaria/csr.pem", privateKey: "/Users/paulofaria/key.pem", responder: router).start()
//        } catch {
//            print(error)
//        }
//    }

    func testUDP() {
        do {
            let listenIP = try IP(port: 40000)
            let socket = try UDPSocket(ip: listenIP)
            let receiveIP = try IP(address: "127.0.0.1", port: 40000)
            let data = try socket.receive(ip: receiveIP)
            print(String(data: data))
        } catch {
            print(error)
        }
    }
}
