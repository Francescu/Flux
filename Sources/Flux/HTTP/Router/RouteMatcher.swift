// RouteMatcher.swift
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

public final class RouteMatcher: RouteMatcherType {
    public var routes: [RouteType] = []

    public var fallback: ResponderType = Responder { request in
        return Response(status: .NotFound)
    }

    public init() {}

    public func addRoute(methods methods: Set<Method>, path: String, responder: ResponderType) {
        let route = Route(methods: methods, path: path, responder: responder)
        routes.append(route)
    }

    public func match(request: Request) -> RouteType? {
        for route in routes where (route as! Route).matches(request) {
            return route
        }
        return nil
    }
}

public struct Route: RouteType {
    public let methods: Set<Method>
    public let path: String
    public let responder: ResponderType

    private let parameterKeys: [String]
    private let regularExpression: Regex

    public init(methods: Set<Method>, path: String, responder: ResponderType) {
        self.methods = methods
        self.path = path
        self.responder = responder

        let parameterRegularExpression = try! Regex(pattern: ":([[:alnum:]]+)")
        let pattern = parameterRegularExpression.replace(path, withTemplate: "([[:alnum:]_-]+)")

        self.parameterKeys = parameterRegularExpression.groups(path)
        self.regularExpression = try! Regex(pattern: "^" + pattern + "$")
    }

    public func matches(request: Request) -> Bool {
        return regularExpression.matches(request.uri.path!) && methods.contains(request.method)
    }

    public func respond(request: Request) throws -> Response {
        var request = request
        let values = regularExpression.groups(request.path)

        for (index, key) in parameterKeys.enumerate() {
            request.pathParameter[key] = values[index]
        }

        return try responder.respond(request)
    }
}

extension Request {
    public var pathParameter: [String: String] {
        set {
            storage["pathParameter"] = newValue
        }
        get {
            return storage["pathParameter"] as? [String: String] ?? [:]
        }
    }
}
