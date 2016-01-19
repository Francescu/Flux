// Date.swift
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

/// Represents a point in time.
public struct Date: Equatable, Comparable, CustomStringConvertible {
    
    // MARK: - Properties
    
    /// The time interval between the date and the reference date (1 January 2001, GMT).
    public var timeIntervalSinceReferenceDate: TimeInterval
    
    /// The time interval between the current date and 1 January 1970, GMT.
    public var timeIntervalSince1970: TimeInterval {
        
        get { return timeIntervalSinceReferenceDate + TimeIntervalBetween1970AndReferenceDate }
        
        set { timeIntervalSinceReferenceDate = timeIntervalSince1970 - TimeIntervalBetween1970AndReferenceDate }
    }
    
    /// Returns the difference between two dates.
    public func timeIntervalSinceDate(date: Date) -> TimeInterval {
        
        return self - date
    }
    
    public var description: String {
        
        return "\(timeIntervalSinceReferenceDate)"
    }
    
    // MARK: - Initialization
    
    /// Creates the date with the current time.
    public init() {
        
        timeIntervalSinceReferenceDate = TimeIntervalSinceReferenceDate()
    }
    
    /// Creates the date with the specified time interval since the reference date (1 January 2001, GMT).
    public init(timeIntervalSinceReferenceDate timeInterval: TimeInterval) {
        
        timeIntervalSinceReferenceDate = timeInterval
    }
    
    /// Creates the date with the specified time interval since 1 January 1970, GMT.
    public init(timeIntervalSince1970 timeInterval: TimeInterval) {
        
        timeIntervalSinceReferenceDate = timeInterval - TimeIntervalBetween1970AndReferenceDate
    }
}

// MARK: - Operator Overloading

public func == (lhs: Date, rhs: Date) -> Bool {
    
    return lhs.timeIntervalSinceReferenceDate == rhs.timeIntervalSinceReferenceDate
}

public func < (lhs: Date, rhs: Date) -> Bool {
    
    return lhs.timeIntervalSinceReferenceDate < rhs.timeIntervalSinceReferenceDate
}

public func <= (lhs: Date, rhs: Date) -> Bool {
    
    return lhs.timeIntervalSinceReferenceDate <= rhs.timeIntervalSinceReferenceDate
}

public func >= (lhs: Date, rhs: Date) -> Bool {
    
    return lhs.timeIntervalSinceReferenceDate >= rhs.timeIntervalSinceReferenceDate
}

public func > (lhs: Date, rhs: Date) -> Bool {
    
    return lhs.timeIntervalSinceReferenceDate > rhs.timeIntervalSinceReferenceDate
}

public func - (lhs: Date, rhs: Date) -> TimeInterval {
    
    return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
}

public func + (lhs: Date, rhs: TimeInterval) -> Date {
    
    return Date(timeIntervalSinceReferenceDate: lhs.timeIntervalSinceReferenceDate + rhs)
}

public func += (inout lhs: Date, rhs: TimeInterval) {
    
    lhs = lhs + rhs
}

public func - (lhs: Date, rhs: TimeInterval) -> Date {
    
    return Date(timeIntervalSinceReferenceDate: lhs.timeIntervalSinceReferenceDate - rhs)
}

public func -= (inout lhs: Date, rhs: TimeInterval) {
    
    lhs = lhs - rhs
}

// MARK: - Functions

/// Returns the time interval between the current date and the reference date (1 January 2001, GMT).
public func TimeIntervalSinceReferenceDate() -> TimeInterval {
    
    return TimeIntervalSince1970() - TimeIntervalBetween1970AndReferenceDate
}

/// Returns the time interval between the current date and 1 January 1970, GMT
public func TimeIntervalSince1970() -> TimeInterval {
    
    return timeval.timeOfDay().timeIntervalValue
}

// MARK: - Constants

/// Time interval difference between two dates, in seconds.
public typealias TimeInterval = Double

///
/// Time interval between the Unix standard reference date of 1 January 1970 and the OpenStep reference date of 1 January 2001
/// This number comes from:
///
/// ```(((31 years * 365 days) + 8  *(days for leap years)* */) = /* total number of days */ * 24 hours * 60 minutes * 60 seconds)```
///
/// - note: This ignores leap-seconds
public let TimeIntervalBetween1970AndReferenceDate: TimeInterval = 978307200.0
