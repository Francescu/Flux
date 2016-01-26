// EventListener.swift
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

public final class EventListener<T> {
	public typealias Listen = (Void throws -> T) -> Void
	
	private let listen: Listen
	private var calls: Int
    var active = true
	
	internal init(calls: Int, listen: Listen) {
		self.calls = calls
		self.listen = listen
	}
	
    func call(event: T) -> Bool {
		calls -= 1

		if calls == 0 {
            active = false
        }

        listen {
            return event
        }

		return active
	}

    func call(error: ErrorType) -> Bool {
        calls -= 1

        if calls == 0 {
            active = false
        }

        listen {
            throw error
        }
        
        return active
    }
	
	public func stop() {
		active = false
	}
}
