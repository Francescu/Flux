// Method.swift
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

public enum Method {
    case DELETE
    case GET
    case HEAD
    case POST
    case PUT
    case CONNECT
    case OPTIONS
    case TRACE
    // WebDAV
    case COPY
    case LOCK
    case MKCOL
    case MOVE
    case PROPFIND
    case PROPPATCH
    case SEARCH
    case UNLOCK
    case BIND
    case REBIND
    case UNBIND
    case ACL
    // Subversion
    case REPORT
    case MKACTIVITY
    case CHECKOUT
    case MERGE
    // UPNP
    case MSEARCH
    case NOTIFY
    case SUBSCRIBE
    case UNSUBSCRIBE
    // RFC-5789
    case PATCH
    case PURGE
    // CalDAV
    case MKCALENDAR
    // RFC-2068, section 19.6.1.2
    case LINK
    case UNLINK

    case UNKNOWN
}

extension Method {
    public static var commonMethods: Set<Method> {
        return [.GET, .POST, .PUT, .PATCH, .DELETE]
    }
}

extension Method: CustomStringConvertible {
    public var description: String {
        switch self {
        case .DELETE:      return "DELETE"
        case .GET:         return "GET"
        case .HEAD:        return "HEAD"
        case .POST:        return "POST"
        case .PUT:         return "PUT"
        case .CONNECT:     return "CONNECT"
        case .OPTIONS:     return "OPTIONS"
        case .TRACE:       return "TRACE"
        case .COPY:        return "COPY"
        case .LOCK:        return "LOCK"
        case .MKCOL:       return "MKCOL"
        case .MOVE:        return "MOVE"
        case .PROPFIND:    return "PROPFIND"
        case .PROPPATCH:   return "PROPPATCH"
        case .SEARCH:      return "SEARCH"
        case .UNLOCK:      return "UNLOCK"
        case .BIND:        return "BIND"
        case .REBIND:      return "REBIND"
        case .UNBIND:      return "UNBIND"
        case .ACL:         return "ACL"
        case .REPORT:      return "REPORT"
        case .MKACTIVITY:  return "MKACTIVITY"
        case .CHECKOUT:    return "CHECKOUT"
        case .MERGE:       return "MERGE"
        case .MSEARCH:     return "MSEARCH"
        case .NOTIFY:      return "NOTIFY"
        case .SUBSCRIBE:   return "SUBSCRIBE"
        case .UNSUBSCRIBE: return "UNSUBSCRIBE"
        case .PATCH:       return "PATCH"
        case .PURGE:       return "PURGE"
        case .MKCALENDAR:  return "MKCALENDAR"
        case .LINK:        return "LINK"
        case .UNLINK:      return "UNLINK"
        default:           return "UNKNOWN"
        }
    }
}

extension Method: Hashable {
    public var hashValue: Int {
        return description.hashValue
    }
}