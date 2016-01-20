//
//  SQLTests.swift
//  Flux
//
//  Created by David Ask on 20/01/16.
//  Copyright © 2016 Zewo. All rights reserved.
//

import XCTest
@testable import Flux

class SQLTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        let statement: Statement = "SELECT * FROM users where id = \(1)"
        
        print(statement)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

}
