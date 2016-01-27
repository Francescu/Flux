//
//  Row.swift
//  MySQL
//
//  Created by David Ask on 10/12/15.
//  Copyright © 2015 Formbound. All rights reserved.
//


public struct MySQLRow: Row {
    public let dataByFieldName: [String: Data?]
    
    public init(dataByFieldName: [String: Data?]) {
        self.dataByFieldName = dataByFieldName
    }
}