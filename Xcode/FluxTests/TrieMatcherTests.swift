import XCTest
@testable import Flux

class TrieMatcherTests: XCTestCase {
    
    func testTrie() {
        var trie = Trie<Character, Int>()
        
        trie.insert("12345".characters, payload: 10101)
        trie.insert("12456".characters)
        trie.insert("12346".characters)
        trie.insert("12344".characters)
        trie.insert("92344".characters)
        
        XCTAssert(trie.contains("12345".characters))
        XCTAssert(trie.contains("92344".characters))
        XCTAssert(!trie.contains("12".characters))
        XCTAssert(!trie.contains("12444".characters))
        XCTAssert(trie.findPayload("12345".characters) == 10101)
        XCTAssert(trie.findPayload("12346".characters) == nil)
    }
    
    func testRouter() {
        
        let router = Router() { route in
            route.get("/hello/world") {_ in print("1"); return Response(status: .OK)}
            route.get("/hello/dan") {_ in print("2"); return Response(status: .OK)}
            route.get("/api/:version") {_ in print("3"); return Response(status: .OK)}
        }
        
        func route(path: String, shouldMatch: Bool) -> Bool {
            let req = try! Request(method: .GET, uri: path)
            
            let status = try! router.respond(req).status
            if shouldMatch {
                return status != .NotFound
            } else {
                return status == .NotFound
            }
        }
        
        XCTAssert(route("/hello/world", shouldMatch: true))
        XCTAssert(route("/hello/dan", shouldMatch: true))
        XCTAssert(route("/hello/world/dan", shouldMatch: false))
        XCTAssert(route("/api/v1", shouldMatch: true))
        XCTAssert(route("/api/v2", shouldMatch: true))
        XCTAssert(route("/api/v1/v1", shouldMatch: false))
        XCTAssert(route("/api/api", shouldMatch: true))
    }
}
