//
//  Trie.swift
//  Flux
//
//  Created by Dan Appel on 1/17/16.
//  Copyright © 2016 Zewo. All rights reserved.
//

struct Trie<Element: Comparable, Payload> {
    let prefix: Element?
    var payload: Payload?
    var ending: Bool
    var children: [Trie<Element, Payload>]
    
    init() {
        self.prefix = nil
        self.payload = nil
        self.ending = false
        self.children = []
    }
    
    init(prefix: Element, payload: Payload?, ending: Bool, children: [Trie<Element, Payload>]) {
        self.prefix = prefix
        self.payload = payload
        self.ending = ending
        self.children = children
    }
}

func ==<Element, Payload where Element: Comparable>(lhs: Trie<Element, Payload>, rhs: Trie<Element, Payload>) -> Bool {
    return lhs.prefix == rhs.prefix
}

func <<Element, Payload where Element: Comparable>(lhs: Trie<Element, Payload>, rhs: Trie<Element, Payload>) -> Bool {
    return lhs.prefix < rhs.prefix
}

extension Trie: Comparable { }

extension Trie {
    
    var description: String {
        return pretty(depth: 0)
    }
    
    func pretty(depth depth: Int) -> String {
        
        let key: String
        if let k = self.prefix {
            key = "\(k)"
        } else {
            key = "head"
        }
        
        let payload: String
        if let p = self.payload {
            payload = ":\(p)"
        } else {
            payload = ""
        }
        
        let children = self.children
            .map { $0.pretty(depth: depth + 1) }
            .reduce("", combine: +)
        
        let pretty = "- \(key)\(payload)" + "\n" + "\(children)"
        
        let indentation = (0..<depth).reduce("", combine: {$0.0 + "  "})
        
        return "\(indentation)\(pretty)"
    }
}

extension Trie {
    mutating func insert<Sequence: SequenceType where Sequence.Generator.Element == Element>(sequence: Sequence, payload: Payload? = nil) {
        insert(sequence.generate(), payload: payload)
    }
    
    mutating func insert<Generator: GeneratorType where Generator.Element == Element>(generator: Generator, payload: Payload? = nil) {
        
        var generator = generator
        
        guard let element = generator.next() else {
            
            self.payload = self.payload ?? payload
            self.ending = true
            
            return
        }
        
        for (index, child) in children.enumerate() {
            var child = child
            if child.prefix == element {
                child.insert(generator, payload: payload)
                self.children[index] = child
                self.children.sortInPlace()
                return
            }
        }
        
        var new = Trie<Element, Payload>(prefix: element, payload: nil, ending: false, children: [])
        
        new.insert(generator, payload: payload)
        
        self.children.append(new)
    }
}

extension Trie {
    func findLast<Sequence: SequenceType where Sequence.Generator.Element == Element>(sequence: Sequence) -> Trie<Element, Payload>? {
        return findLast(sequence.generate())
    }
    
    func findLast<Generator: GeneratorType where Generator.Element == Element>(generator: Generator) -> Trie<Element, Payload>? {
        
        var generator = generator
        
        guard let element = generator.next() else {
            guard ending == true else { return nil }
            return self
        }
        
        for child in children {
            if child.prefix == element {
                return child.findLast(generator)
            }
        }
        
        return nil
    }
}

extension Trie {
    func findPayload<Sequence: SequenceType where Sequence.Generator.Element == Element>(sequence: Sequence) -> Payload? {
        return findPayload(sequence.generate())
    }
    func findPayload<Generator: GeneratorType where Generator.Element == Element>(generator: Generator) -> Payload? {
        return findLast(generator)?.payload
    }
}

extension Trie {
    func contains<Sequence: SequenceType where Sequence.Generator.Element == Element>(sequence: Sequence) -> Bool {
        return contains(sequence.generate())
    }
    
    func contains<Generator: GeneratorType where Generator.Element == Element>(generator: Generator) -> Bool {
        return findLast(generator) != nil
    }
}

extension Trie where Payload: Equatable {
    func findByPayload(payload: Payload) -> [Element]? {
        
        if self.payload == payload {
            // not sure what to do if it doesnt have a prefix
            if let prefix = self.prefix {
                return [prefix]
            }
            return []
        }
        
        for child in children {
            if let prefixes = child.findByPayload(payload) {
                if let prefix = self.prefix {
                    return [prefix] + prefixes
                }
                return prefixes
            }
        }
        return nil
    }
}
