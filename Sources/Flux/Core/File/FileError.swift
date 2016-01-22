// FileError.swift
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

public enum FileError: ErrorType {
    case Unknown(description: String)
    case NoBufferSpaceAvailabe(description: String, data: Data)
    case OperationTimedOut(description: String, data: Data)
    case ClosedFile(description: String)

    static func lastReceiveErrorWithData(source: Data, bytesProcessed: Int) -> FileError {
        let data = processedDataFromSource(source, bytesProcessed: bytesProcessed)
        return lastErrorWithData(data)
    }

    static func lastErrorWithData(data: Data) -> FileError {
        switch errno {
        case ENOBUFS:
            return .NoBufferSpaceAvailabe(description: lastErrorDescription, data: data)
        case ETIMEDOUT:
            return .OperationTimedOut(description: lastErrorDescription, data: data)
        default:
            return .Unknown(description: lastErrorDescription)
        }
    }

static var lastErrorDescription: String {
    return String.fromCString(strerror(errno))!
    }

static var lastError: FileError {
    // TODO: Switch on errno
    return .Unknown(description: lastErrorDescription)
    }

static var closedFileError: FileError {
    return FileError.ClosedFile(description: "Closed file")
    }

    static func assertNoError() throws {
        if errno != 0 {
            throw FileError.lastError
        }
    }

    static func assertNoReceiveErrorWithData(data: Data, bytesProcessed: Int) throws {
        if errno != 0 {
            throw FileError.lastReceiveErrorWithData(data, bytesProcessed: bytesProcessed)
        }
    }
}

//func remainingDataFromSource(data: Data, bytesProcessed: Int) -> Data {
//    return data[data.count - bytesProcessed ..< data.count]
//}
//
//func processedDataFromSource(data: Data, bytesProcessed: Int) -> Data {
//    return data[0 ..< bytesProcessed]
//}

extension FileError: CustomStringConvertible {
    public var description: String {
        switch self {
        case Unknown(let description):
            return description
        case NoBufferSpaceAvailabe(let description, _):
            return description
        case OperationTimedOut(let description, _):
            return description
        case ClosedFile(let description):
            return description
        }
    }
}
