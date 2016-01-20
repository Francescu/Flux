// MultipartBodyParserMiddleware.swift
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

public struct Multipart {
    public let contentDisposition: String
    public let contentDispositionParameters: [String: String]
    public let contentType: String?
    public let body: Data
}

enum MultipartBodyError: ErrorType {
    case MultipartBodyNotFound
}

extension Request {
    private var multipartFormBodyKey: String {
        return "multipartFormBody"
    }

    public var multipartBody: [Multipart] {
        set {
            storage[multipartFormBodyKey] = newValue
        }
        get {
            return storage[multipartFormBodyKey] as? [Multipart] ?? []
        }
    }

    public func getMultipartBody() throws -> [Multipart] {
        if let multipartBody = storage[multipartFormBodyKey] as? [Multipart] {
            return multipartBody
        }

        throw MultipartBodyError.MultipartBodyNotFound
    }
}

public struct MultipartBodyParserMiddleware: MiddlewareType {
    public init() {}
    
    public func respond(request: Request, chain: ChainType) throws -> Response {
        var request = request

        if let
            mediaType = request.contentType,
            boundary = mediaType.parameters["boundary"]
            where mediaType == multipartFormMediaType  {
                request.multipartBody = try self.getMultipartsFromBody(request.body, boundary: boundary)
        }

        return try chain.proceed(request)
    }
    
    private func getMultipartsFromBody(body: Data, boundary: String) throws -> [Multipart] {
        var multiparts: [Multipart] = []
        var generator = body.generate()

        func getLine() throws -> String? {
            let carriageReturn: UInt8 = 13
            let newLine: UInt8 = 10
            var bytes: [UInt8]? = .None

            while let byte = generator.next() where byte != newLine {
                if bytes == nil {
                    bytes = []
                }

                if byte != carriageReturn {
                    bytes!.append(byte)
                }
            }

            if let bytes = bytes {
                return try String(data: Data(bytes: bytes))
            }

            return nil
        }

        func getData(boundary: String) -> Data? {
            var boundary = "--\(boundary)"
            let boundaryLastIndex = boundary.utf8.count - 1
            var boundaryIndex = boundaryLastIndex
            var bytes: [UInt8]? = nil

            func getByteForIndex(index: Int) -> UInt8 {
                return boundary.utf8[boundary.utf8.startIndex.advancedBy(index)]
            }

            func getByteForReversedIndex(index: Int) -> UInt8? {
                if bytes!.count - index - 1 + boundaryLastIndex < 0 {
                    return nil
                }

                return bytes![bytes!.count + index - 1 - boundaryLastIndex]
            }

            LOOP: while let byte = generator.next() {
                if bytes == nil {
                    bytes = []
                }

                bytes!.append(byte)

                while let crazyByte = getByteForReversedIndex(boundaryIndex) {
                    if crazyByte == getByteForIndex(boundaryIndex) {
                        boundaryIndex--
                    } else {
                        boundaryIndex = boundaryLastIndex
                        break
                    }

                    if boundaryIndex == 0 {
                        break LOOP
                    }
                }
            }

            if let bytes = bytes {
                let bytesWithoutBoundary = bytes[0 ..< bytes.count - boundaryLastIndex - 3]
                return Data(bytes: Array(bytesWithoutBoundary))
            }

            return nil
        }

        while let boundaryLine = try getLine() {
            if boundaryLine == "--\(boundary)" {
                let contentDisposition: String
                var contentDispositionParameters: [String: String] = [:]
                var contentType: String? = .None
                let body: Data

                if let contentDispositionLine = try getLine() {
                    let contentDispositionArray = contentDispositionLine.splitBy(";")
                    let contentDispositionToken = contentDispositionArray[0]
                    contentDisposition = contentDispositionToken.splitBy(":")[1].trim()

                    for index in 1 ..< contentDispositionArray.count {
                        let parameter = contentDispositionArray[index].trim()
                        let parameterArray = parameter.splitBy("=")
                        let parameterKey = parameterArray[0]
                        let parameterValue = parameterArray[1].trim()
                        contentDispositionParameters[parameterKey] = parameterValue
                    }

                    if let secondLine = try getLine() {
                        if secondLine == "" {
                            body = getData(boundary)!
                        } else {
                            let contentTypeLine = secondLine
                            contentType = contentTypeLine.splitBy(":")[1].trim()
                            try getLine()
                            body = getData(boundary)!
                        }

                        let multipart = Multipart(
                            contentDisposition: contentDisposition,
                            contentDispositionParameters: contentDispositionParameters,
                            contentType: contentType,
                            body: body
                        )

                        multiparts.append(multipart)
                    }
                }
            }
        }

        return multiparts
    }
}