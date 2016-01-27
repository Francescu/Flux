//
//  PostgreSQLTests.swift
//  Flux
//
//  Created by David Ask on 27/01/16.
//  Copyright © 2016 Zewo. All rights reserved.
//

import Flux
import XCTest

class PostgreSQLTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        let connection = PostgreSQLConnection("postgres://localhost/swift_test")
        
        do {
            try connection.open()
            
            let result = try connection.execute("SELECT * FROM users")
            
            print(Array(result))
        }
        catch {
            print(error)
            print("!")
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

}
