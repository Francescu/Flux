// Time.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Source code based on work from https://github.com/PureSwift/SwiftFoundation
// Created by Alsey Coleman Miller on 7/22/15.

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public extension timeval {
    
    static func timeOfDay() -> timeval {
        
        var timeStamp = timeval()
        
        guard gettimeofday(&timeStamp, nil) == 0 else {
            return timeval(timeInterval: 0)
        }
        
        return timeStamp
    }
    
    init(timeInterval: TimeInterval) {
        
        let (integerValue, decimalValue) = modf(timeInterval)
        
        let million: TimeInterval = 1000000.0
        
        let microseconds = decimalValue * million
        
        self.init(tv_sec: Int(integerValue), tv_usec: POSIXMicroseconds(microseconds))
    }
    
    var timeIntervalValue: TimeInterval {
        
        let secondsSince1970 = TimeInterval(self.tv_sec)
        
        let million: TimeInterval = 1000000.0
        
        let microseconds = TimeInterval(self.tv_usec) / million
        
        return secondsSince1970 + microseconds
    }
}

public extension timespec {
    
    init(timeInterval: TimeInterval) {
        
        let (integerValue, decimalValue) = modf(timeInterval)
        
        let billion: TimeInterval = 1000000000.0
        
        let nanoseconds = decimalValue * billion
        
        self.init(tv_sec: Int(integerValue), tv_nsec: Int(nanoseconds))
    }
    
    var timeIntervalValue: TimeInterval {
        
        let secondsSince1970 = TimeInterval(self.tv_sec)
        
        let billion: TimeInterval = 1000000000.0
        
        let nanoseconds = TimeInterval(self.tv_nsec) / billion
        
        return secondsSince1970 + nanoseconds
    }
}

public extension tm {
    
    init(UTCSecondsSince1970: time_t) {
        
        var seconds = UTCSecondsSince1970
        
        let timePointer = gmtime(&seconds)
        
        self = timePointer.memory
    }
}

// MARK: - Cross-Platform Support

#if os(Linux)
    public typealias POSIXMicroseconds = __suseconds_t
    
    public func modf(value: Double) -> (Double, Double) {
        
        var integerValue: Double = 0
        
        let decimalValue = modf(value, &integerValue)
        
        return (decimalValue, integerValue)
    }
#else
    public typealias POSIXMicroseconds = __darwin_suseconds_t
#endif
