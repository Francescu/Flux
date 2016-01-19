// IP.swift
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
import CLibvenice

public enum IPMode {
    case IPV4
    case IPV6
    case IPV4Prefered
    case IPV6Prefered
}

extension IPMode {
    var code: Int32 {
        switch self {
        case .IPV4: return 1
        case .IPV6: return 2
        case .IPV4Prefered: return 3
        case .IPV6Prefered: return 4
        }
    }
}

public struct IP {
    let address: ipaddr

    init(address: ipaddr) {
        self.address = address
    }

    public init(port: Int, mode: IPMode = .IPV4) throws {
        if port < 0 || port > 0xffff {
            throw IPError(description: "port should be between 0 and 0xffff")
        }

        self.address = iplocal(nil, Int32(port), mode.code)

        if errno != 0 {
            let description = IPError.lastSystemErrorDescription
            throw IPError(description: description)
        }
    }

    public init(networkInterface: String, port: Int, mode: IPMode = .IPV4) throws {
        if port < 0 || port > 0xffff {
            throw IPError(description: "port should be between 0 and 0xffff")
        }

        self.address = iplocal(networkInterface, Int32(port), mode.code)

        if errno != 0 {
            let description = IPError.lastSystemErrorDescription
            throw IPError(description: description)
        }
    }

    public init(address: String, port: Int, mode: IPMode = .IPV4, deadline: Deadline = noDeadline) throws {
        if port < 0 || port > 0xffff {
            throw IPError(description: "port should be between 0 and 0xffff")
        }
        
        self.address = ipremote(address, Int32(port), mode.code, deadline)

        if errno != 0 {
            let description = IPError.lastSystemErrorDescription
            throw IPError(description: description)
        }
    }
}

extension IP: CustomStringConvertible {
    public var description: String {
        var buffer: [Int8] = [Int8](count: 46, repeatedValue: 0)
        ipaddrstr(address, &buffer)
        return String.fromCString(buffer)!
    }
}