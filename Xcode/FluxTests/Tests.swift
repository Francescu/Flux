import XCTest
import Flux

class HTTPTests: XCTestCase {
    func test() {
        let router = Router { route in
            route.get("/:yo") { request in
                print(request.debugDescription)
                return Response(status: .OK, body: request.pathParameter["yo"]!)
            }
        }
        Server(port: 8080, responder: router).start()
    }
}