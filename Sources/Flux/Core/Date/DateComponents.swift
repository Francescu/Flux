// DateComponents.swift
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


#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif


public struct DateComponents {
    public enum Component {
        case Second
        case Minute
        case Hour
        case DayOfMonth
        case Month
        case Year
        case Weekday
        case DayOfYear
    }
    
    public var second: Int32 = 0
    public var minute: Int32 = 0
    public var hour: Int32 = 0
    public var dayOfMonth: Int32 = 1
    public var month: Int32 = 1
    public var year: Int32 = 0
    public var weekday: Int32
    public var dayOfYear: Int32 = 1
    
    public init(timeInterval: TimeInterval) {
        self.init(
            brokenDown: tm(
                UTCSecondsSince1970: timeval(timeInterval: timeInterval).tv_sec
            )
        )
    }
    
    public init() {
        weekday = 0
    }
    
    public init(fromDate date: Date) {
        self.init(timeInterval: date.timeIntervalSince1970)
    }
    
    public var date: Date {
        return Date(timeIntervalSince1970: timeInterval)
    }
    
    public mutating func setValue(value: Int32, forComponent component: Component) {
        switch component {
        case .Second:
            second = value
            break
        case .Minute:
            minute = value
            break
        case .Hour:
            hour = value
            break
        case .DayOfMonth:
            dayOfMonth = value
            break
        case .Month:
            month = value
            break
        case .Year:
            year = value
            break
        case .Weekday:
            weekday = value
            break
        case .DayOfYear:
            dayOfYear = value
            break
        }
    }
    
    public func valueForComponent(component: Component) -> Int32 {
        switch component {
        case .Second:
            return second
        case .Minute:
            return minute
        case .Hour:
            return hour
        case .DayOfMonth:
            return dayOfMonth
        case .Month:
            return month
        case .Year:
            return year
        case .Weekday:
            return weekday
        case .DayOfYear:
            return dayOfYear
        }
    }
    
    private init(brokenDown: tm) {
        second = brokenDown.tm_sec
        minute = brokenDown.tm_min
        hour = brokenDown.tm_hour
        dayOfMonth = brokenDown.tm_mday
        month = brokenDown.tm_mon + 1
        year = 1900 + brokenDown.tm_year
        weekday = brokenDown.tm_wday
        dayOfYear = brokenDown.tm_yday
    }
    
    private var brokenDown: tm {
        return tm.init(
            tm_sec: second,
            tm_min: minute,
            tm_hour: hour,
            tm_mday: dayOfMonth,
            tm_mon: month - 1,
            tm_year: year - 1900,
            tm_wday: weekday,
            tm_yday: dayOfYear,
            tm_isdst: -1,
            tm_gmtoff: 0,
            tm_zone: nil
        )
    }
    
    private var timeInterval: TimeInterval {
        var time = brokenDown
        return TimeInterval(timegm(&time))
    }
}
