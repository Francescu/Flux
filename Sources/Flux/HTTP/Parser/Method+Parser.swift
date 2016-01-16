// Method+HTTPParser.swift
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

extension Method {
    init(code: Int) {
        switch code {
        case 00: self = DELETE
        case 01: self = GET
        case 02: self = HEAD
        case 03: self = POST
        case 04: self = PUT
        case 05: self = CONNECT
        case 06: self = OPTIONS
        case 07: self = TRACE
        case 08: self = COPY
        case 09: self = LOCK
        case 10: self = MKCOL
        case 11: self = MOVE
        case 12: self = PROPFIND
        case 13: self = PROPPATCH
        case 14: self = SEARCH
        case 15: self = UNLOCK
        case 16: self = BIND
        case 17: self = REBIND
        case 18: self = UNBIND
        case 19: self = ACL
        case 20: self = REPORT
        case 21: self = MKACTIVITY
        case 22: self = CHECKOUT
        case 23: self = MERGE
        case 24: self = MSEARCH
        case 25: self = NOTIFY
        case 26: self = SUBSCRIBE
        case 27: self = UNSUBSCRIBE
        case 28: self = PATCH
        case 29: self = PURGE
        case 30: self = MKCALENDAR
        case 31: self = LINK
        case 32: self = UNLINK
        default: self = UNKNOWN
        }
    }
}