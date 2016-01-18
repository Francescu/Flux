import XCTest
@testable import Flux

class HTTPTests: XCTestCase {
    func test() {
        let router = Router { route in
            route.get("/:hello") { request in
                print(request.debugDescription)
                return Response(status: .OK, body: request.pathParameter["hello"]!)
            }
        }
        
//        Server(port: 8080, responder: router).start()
    }
}
