//
//  Stack.swift
//  NutView
//
//  Created by Filip Klembara on 2/3/18.
//

struct Stack<T> {
    private var array: [T]
    init() {
        array = [T]()
    }
    mutating func push(_ element: T) {
        array.append(element)
    }
    mutating func push(_ elements: [T]) {
        elements.reversed().forEach { push($0) }
    }
    mutating func push(_ elements: T...) {
        push(elements)
    }
    mutating func pop() -> T? {
        guard !array.isEmpty else {
            return nil
        }
        return array.removeLast()
    }
    var isEmpty: Bool {
        return array.isEmpty
    }
    var count: Int {
        return array.count
    }
}
