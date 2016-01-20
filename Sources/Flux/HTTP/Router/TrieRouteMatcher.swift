//
//  TrieRouteMatcher.swift
//  Flux
//
//  Created by Dan Appel on 1/17/16.
//  Copyright © 2016 Zewo. All rights reserved.
//

public struct TrieRouteMatcher: RouteMatcherType, CustomStringConvertible {
    
    private var componentsTrie = Trie<Character, Int>()
    private var routesTrie = Trie<Int, Route>()
    
    public let routes: [Route]
    
    public var description: String {
        return componentsTrie.description + "\n" + routesTrie.description
    }
    
    public init(routes: [Route]) {
        self.routes = routes
        
        var nextComponentId = 1
        
        for route in routes {
            
            // turn component (string) into an id (integer) for fast comparisons
            let componentIds = route.path.splitBy("/").map { component -> Int in
                
                // if it already has a component with the same name, use that id
                if let id = componentsTrie.findPayload(component.characters) {
                    return id
                }
                
                let id: Int
                
                if component.characters.first == ":" {
                    // if component is a parameter, give it a negative id
                    id = -nextComponentId
                } else {
                    // normal component, give it a positive id
                    id = nextComponentId
                }
                
                // increment id for next component
                nextComponentId += 1
                
                // insert the component into the trie with the next id
                componentsTrie.insert(component.characters, payload: id)
                
                return id
            }
            
            // insert the components with the end node containing the route
            routesTrie.insert(componentIds, payload: route)
        }
    }
    
    func getParameterFromId(id: Int) -> String? {
        guard let parameterChars = self.componentsTrie.findByPayload(id) else { return nil }
        let parameter = parameterChars.dropFirst().reduce("") { $0.0 + String($0.1)} // drop colon (":"), then combine characters into string
        return parameter
    }
    
    public func match(request: Request) -> Route? {
        guard let path = request.path else {
            return nil
        }

        let components = path.splitBy("/")
        
        // topmost route node. children are searched for route matches,
        // if they match, that matching node gets set to head
        var head = routesTrie
        
        // pseudo-lazy initiation
        var parameters: [String:String]? = nil
        
        componentLoop: for component in components {
            
            // search for component in the components dictionary
            let id = componentsTrie.findPayload(component.characters)
            
            
            // either parameter or 404
            if id == nil {
                
                for child in head.children {
                    
                    // if the id of the route component is negative,
                    // its a parameter
                    if child.prefix < 0 {
                        head = child
                        if parameters == nil { parameters = [String:String]() }
                        parameters![getParameterFromId(child.prefix!)!] = component
                        continue componentLoop
                    }
                }
                
                // no routes matched
                return nil
            }
            
            
            // component exists in the routes
            for child in head.children {
                
                // still could be a parameter
                // ex: route.get("/api/:version")
                // request: /api/api
                if child.prefix < 0 {
                    head = child
                    if parameters == nil { parameters = [String:String]() }
                    parameters![getParameterFromId(child.prefix!)!] = component
                    continue componentLoop
                }
                
                // normal, static route
                if child.prefix == id {
                    head = child
                    continue componentLoop
                }
            }
            
            // no routes matched
            return nil
        }
        
        // if the last node has children,
        // the parameters aren't wrong but aren't long enough
        // ie: route: /api/v1/v2/v3, given: /api/v1/v2
        if !head.children.isEmpty {
            return nil
        }
        
        // get the actual route
        guard let route = head.payload else { return nil }
        
        // no parameters? no problem
        guard let pathParameters = parameters else { return route }
        
        let wrappedRoute = Route(methods: route.methods, path: route.path, responder: Responder { req in
            var req = req
            for (key, parameter) in pathParameters {
                req.pathParameter[key] = parameter
            }
            return try route.respond(req)
        })

        return wrappedRoute
    }
}
