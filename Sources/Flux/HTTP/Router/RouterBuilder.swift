// RouterBuilder.swift
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

public final class RouterBuilder {
    let basePath: String
    var routes: [Route] = []
    
    var fallback: ResponderType = Responder { _ in
        return Response(status: .NotFound)
    }

    init(basePath: String) {
        self.basePath = basePath
    }

    public func fallback(middleware middleware: MiddlewareType..., respond: Respond) {
        _fallback(middleware, responder: Responder(respond: respond))
    }

    public func fallback(middleware middleware: MiddlewareType..., responder: ResponderType) {
        _fallback(middleware, responder: responder)
    }

    private func _fallback(middleware: [MiddlewareType], responder: ResponderType) {
        fallback = middleware.intercept(responder)
    }

    public func router(path: String, middleware: MiddlewareType..., router: Router) {
        let prefix = basePath + path

        let newRoutes = router.matcher.routes.map { route in
            return Route(
                methods: route.methods,
                path: prefix + route.path,
                responder: middleware.intercept { request in
                    var request = request

                    guard let path = request.path else {
                        return Response(status: .BadRequest)
                    }

                    let prefixLength = prefix.characters.count - 1
                    request.uri.path = path.dropFirstCharacters(prefixLength)
                    return try router.respond(request)
                }
            )
        }

        routes.appendContentsOf(newRoutes)
    }

    public func any(path: String, middleware: MiddlewareType..., respond: Respond) {
        _any(path, middleware: middleware, responder: Responder(respond: respond))
    }

    public func any(path: String, middleware: MiddlewareType..., responder: ResponderType) {
        _any(path, middleware: middleware, responder: responder)
    }

    private func _any(path: String, middleware: [MiddlewareType], responder: ResponderType) {
        _methods(Method.commonMethods, path: path, middleware: middleware, responder: responder)
    }

    public func get(path: String, middleware: MiddlewareType..., respond: Respond) {
        _get(path, middleware: middleware, responder: Responder(respond: respond))
    }

    public func get(path: String, middleware: MiddlewareType..., responder: ResponderType) {
        _get(path, middleware: middleware, responder: responder)
    }

    private func _get(path: String, middleware: [MiddlewareType], responder: ResponderType) {
        _methods([.GET], path: path, middleware: middleware, responder: responder)
    }

    public func post(path: String, middleware: MiddlewareType..., respond: Respond) {
        _post(path, middleware: middleware, responder: Responder(respond: respond))
    }

    public func post(path: String, middleware: MiddlewareType..., responder: ResponderType) {
        _post(path, middleware: middleware, responder: responder)
    }

    private func _post(path: String, middleware: [MiddlewareType], responder: ResponderType) {
        _methods([.POST], path: path, middleware: middleware, responder: responder)
    }

    public func put(path: String, middleware: MiddlewareType..., respond: Respond) {
        _put(path, middleware: middleware, responder: Responder(respond: respond))
    }

    public func put(path: String, middleware: MiddlewareType..., responder: ResponderType) {
        _put(path, middleware: middleware, responder: responder)
    }

    private func _put(path: String, middleware: [MiddlewareType], responder: ResponderType) {
        _methods([.PUT], path: path, middleware: middleware, responder: responder)
    }

    public func patch(path: String, middleware: MiddlewareType..., respond: Respond) {
        _patch(path, middleware: middleware, responder: Responder(respond: respond))
    }

    public func patch(path: String, middleware: MiddlewareType..., responder: ResponderType) {
        _patch(path, middleware: middleware, responder: responder)
    }

    private func _patch(path: String, middleware: [MiddlewareType], responder: ResponderType) {
        _methods([.PATCH], path: path, middleware: middleware, responder: responder)
    }

    public func delete(path: String, middleware: MiddlewareType..., respond: Respond) {
        _delete(path, middleware: middleware, responder: Responder(respond: respond))
    }

    public func delete(path: String, middleware: MiddlewareType..., responder: ResponderType) {
        _delete(path, middleware: middleware, responder: responder)
    }

    private func _delete(path: String, middleware: [MiddlewareType], responder: ResponderType) {
        _methods([.DELETE], path: path, middleware: middleware, responder: responder)
    }

    public func methods(m: Set<Method>, path: String, middleware: MiddlewareType..., respond: Respond) {
        _methods(m, path: path, middleware: middleware, responder: Responder(respond: respond))
    }

    public func methods(m: Set<Method>, path: String, middleware: MiddlewareType..., responder: ResponderType) {
        _methods(m, path: path, middleware: middleware, responder: responder)
    }

    private func _methods(methods: Set<Method>, path: String, middleware: [MiddlewareType], responder: ResponderType) {
        let route = Route(
            methods: methods,
            path: basePath + path,
            responder: middleware.intercept(responder)
        )
        routes.append(route)
    }
}

extension Router {
    public init(_ basePath: String = "", middleware: MiddlewareType..., build: (route: RouterBuilder) -> Void) {
        let builder = RouterBuilder(basePath: basePath)
        build(route: builder)
        self.init(
            middleware: middleware,
            matcher: TrieRouteMatcher(routes: builder.routes),
            fallback: builder.fallback
        )
    }
}
