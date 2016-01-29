// Client.swift
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

public struct Client: ClientType {
    public let client: StreamClientType
    public let serializer: RequestStreamSerializerType
    public let parser: ResponseStreamParserType

    public init(client: StreamClientType, serializer: RequestStreamSerializerType, parser: ResponseStreamParserType) {
        self.client = client
        self.serializer = serializer
        self.parser = parser
    }
}

extension Client {
    public init(host: String, port: Int, serializer: RequestStreamSerializerType = RequestStreamSerializer(), parser: ResponseStreamParserType = ResponseStreamParser()) throws {
        self.init(
            client: try TCPStreamClient(host: host, port: port),
            serializer: serializer,
            parser: parser
        )
    }

    public init(host: String, port: Int, certificateChain: String, serializer: RequestStreamSerializerType = RequestStreamSerializer(), parser: ResponseStreamParserType = ResponseStreamParser()) throws {
        self.init(
            client: try TCPSSLStreamClient(
                host: host,
                port: port,
                certificateChain: certificateChain
            ),
            serializer: serializer,
            parser: parser
        )
    }
}
