//
//  Result.swift
//  MySQL
//
//  Created by David Ask on 10/12/15.
//  Copyright © 2015 Formbound. All rights reserved.
//

#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

import CMySQL

public class MySQLResult: Result {
    
    public struct Generator: ResultGenerator {
        
        let result: MySQLResult
        var index: Int = 0
        
        public init(result: MySQLResult) {
            self.result = result
        }
        
        public mutating func next() -> MySQLRow? {
            
            guard index < result.count else {
                return nil
            }
            
            defer {
                index += 1
            }
            
            return result[index]
        }
    }
    
    public let resultPointer: UnsafeMutablePointer<MYSQL_RES>
    
    public init(_ resultPointer: UnsafeMutablePointer<MYSQL_RES>) {
        self.resultPointer = resultPointer
    }
    
    deinit {
        clear()
    }
    
    public func clear() {
        mysql_free_result(resultPointer)
    }
    
    public func generate() -> Generator {
        return Generator(result: self)
    }
    
    public subscript(position: Int) -> MySQLRow {
        
        var result: [String: Data?] = [:]
        
        mysql_data_seek(resultPointer, UInt64(position))
        
        let row = mysql_fetch_row(resultPointer)
        
        let lengths = mysql_fetch_lengths(resultPointer)
        
        for (fieldIndex, field) in fields.enumerate() {

            let val = row[fieldIndex]
            let length = Int(lengths[fieldIndex])
            
            var buffer = [UInt8](count: length, repeatedValue: 0)
            
            memcpy(&buffer, val, length)
            
            result[field.name] = Data(bytes: buffer)
        }
        
        return MySQLRow(dataByFieldName: result)
    }
    
    public var count: Int {
        return Int(mysql_num_rows(resultPointer))
    }
    
    public var startIndex: Int {
        return 0
    }
    
    public var endIndex: Int {
        return count
    }
    
    public lazy var fields: [MySQLField] = {
        var result: [MySQLField] = []
        
        for i in 0..<mysql_num_fields(self.resultPointer) {
            
            result.append(
                MySQLField(mysql_fetch_field_direct(self.resultPointer, i))
            )
        }
        
        return result
        
    }()
}
