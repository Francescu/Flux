// ContentNegotiatorMiddleware.swift
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

public let mediaTypeParsers: MediaTypeParsers = {
    let parsers = MediaTypeParsers()
    parsers.addParser(URLEncodedFormParser(), forMediaType: URLEncodedFormMediaType)
    parsers.addParser(JSONParser(), forMediaType: JSONMediaType)
    return parsers
}()

public enum MediaTypeParsersError: ErrorType {
    case NoSuitableParser
    case MediaTypeNotFound
}

public final class MediaTypeParsers {
    private var mediaTypeParsers: [(MediaType, InterchangeDataParser)] = []

    var mediaTypes: [MediaType] {
        return mediaTypeParsers.map({$0.0})
    }

    public init() {}

    public func setDefaultMediaType(targetMediaType: MediaType) throws {
        for index in 0 ..< mediaTypeParsers.count {
            let tuple = mediaTypeParsers[index]
            if tuple.0 == targetMediaType {
                mediaTypeParsers.removeAtIndex(index)
                mediaTypeParsers.insert(tuple, atIndex: 0)
                return
            }
        }

        throw MediaTypeParsersError.MediaTypeNotFound
    }

    public func setMediaTypePriority(mediaTypes: MediaType...) throws {
        try setMediaTypePriority(mediaTypes)
    }

    public func setMediaTypePriority(mediaTypes: [MediaType]) throws {
        for mediaType in mediaTypes.reverse() {
            try setDefaultMediaType(mediaType)
        }
    }

    public func addParser(parser: InterchangeDataParser, forMediaType mediaType: MediaType) {
        mediaTypeParsers.append(mediaType, parser)
    }

    public func parsersForMediaType(targetMediaType: MediaType) -> [(MediaType, InterchangeDataParser)] {
        return mediaTypeParsers.reduce([]) {
            if $1.0.matches(targetMediaType) {
                return $0 + [($1.0, $1.1)]
            } else {
                return $0
            }
        }
    }

    public func parseData(data: Data, mediaType: MediaType) throws -> (MediaType, InterchangeData) {
        var lastError: ErrorType?

        for (mediaType, parser) in parsersForMediaType(mediaType) {
            do {
                return try (mediaType, parser.parse(data))
            } catch {
                lastError = error
                continue
            }
        }

        if let lastError = lastError {
            throw lastError
        } else {
            throw MediaTypeParsersError.NoSuitableParser
        }
    }
}







public let mediaTypeSerializers: MediaTypeSerializers = {
    let serializers = MediaTypeSerializers()
    serializers.addSerializer(URLEncodedFormSerializer(), forMediaType: URLEncodedFormMediaType)
    serializers.addSerializer(JSONSerializer(), forMediaType: JSONMediaType)
    return serializers
}()

public enum MediaTypeSerializersError: ErrorType {
    case NoSuitableSerializer
    case MediaTypeNotFound
}

public final class MediaTypeSerializers {
    private var mediaTypeSerializers: [(MediaType, InterchangeDataSerializer)] = []

    var mediaTypes: [MediaType] {
        return mediaTypeSerializers.map({$0.0})
    }

    public init() {}

    public func setDefaultMediaType(targetMediaType: MediaType) throws {
        for index in 0 ..< mediaTypeSerializers.count {
            let tuple = mediaTypeSerializers[index]
            if tuple.0 == targetMediaType {
                mediaTypeSerializers.removeAtIndex(index)
                mediaTypeSerializers.insert(tuple, atIndex: 0)
                return
            }
        }

        throw MediaTypeSerializersError.MediaTypeNotFound
    }

    public func setMediaTypePriority(mediaTypes: MediaType...) throws {
        try setMediaTypePriority(mediaTypes)
    }

    public func setMediaTypePriority(mediaTypes: [MediaType]) throws {
        for mediaType in mediaTypes.reverse() {
            try setDefaultMediaType(mediaType)
        }
    }

    public func addSerializer(serializer: InterchangeDataSerializer, forMediaType mediaType: MediaType) {
        mediaTypeSerializers.append(mediaType, serializer)
    }

    public func serializersForMediaType(targetMediaType: MediaType) -> [(MediaType, InterchangeDataSerializer)] {
        return mediaTypeSerializers.reduce([]) {
            if $1.0.matches(targetMediaType) {
                return $0 + [($1.0, $1.1)]
            } else {
                return $0
            }
        }
    }

    public func serializeData(data: InterchangeData, mediaTypes: [MediaType]) throws -> (MediaType, Data) {
        var lastError: ErrorType?

        for acceptedType in mediaTypes {
            for (mediaType, serializer) in serializersForMediaType(acceptedType) {
                do {
                    return try (mediaType, serializer.serialize(data))
                } catch {
                    lastError = error
                    continue
                }
            }
        }

        if let lastError = lastError {
            throw lastError
        } else {
            throw MediaTypeSerializersError.NoSuitableSerializer
        }
    }
}

public let contentNegotiator = ContentNegotiatorMiddleware()

public final class ContentNegotiatorMiddleware: MiddlewareType {
    public func respond(request: Request, chain: ChainType) throws -> Response {
        var request = request

        if let contentType = request.contentType {
            do {
                let (_, content) = try mediaTypeParsers.parseData(request.body, mediaType: contentType)
                request.content = content
            } catch MediaTypeParsersError.NoSuitableParser {
                return Response(status: .UnsupportedMediaType)
            } catch {
                return Response(status: .BadRequest)
            }
        }

        var response = try chain.proceed(request)

        if let content = response.content {
            do {
                let (mediaType, body) = try mediaTypeSerializers.serializeData(content, mediaTypes: request.accept)
                response.contentType = mediaType
                response.body = body
            } catch MediaTypeSerializersError.NoSuitableSerializer {
                return Response(status: .NotAcceptable)
            } catch {
                return Response(status: .InternalServerError)
            }
        }

        return response
    }
}











public func clientContentNegotiator(mediaTypes: MediaType...) -> ClientContentNegotiatorMiddleware {
    return ClientContentNegotiatorMiddleware(mediaTypes: mediaTypes)
}

public final class ClientContentNegotiatorMiddleware: MiddlewareType {
    public let mediaTypes: [MediaType]

    public init(mediaTypes: [MediaType]) {
        self.mediaTypes = mediaTypes
    }

    public func respond(request: Request, chain: ChainType) throws -> Response {
        var request = request

        request.accept = mediaTypeParsers.mediaTypes
        
        if let content = request.content {
            let (mediaType, body) = try mediaTypeSerializers.serializeData(content, mediaTypes: mediaTypes)
            request.contentType = mediaType
            request.body = body
        }

        var response = try chain.proceed(request)

        print(response.debugDescription)

        if let contentType = response.contentType {
            let (_, content) = try mediaTypeParsers.parseData(response.body, mediaType: contentType)
            response.content = content
        }
        
        return response
    }
}