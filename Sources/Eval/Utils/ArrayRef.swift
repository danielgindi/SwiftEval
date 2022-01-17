//
//  ArrayRef.swift
//  
//
//  Created by Daniel Cohen Gindi on 17/01/2022.
//

internal class ArrayRef<T> {
    init() {}
    
    init(_ items: [T]) {
        self.items = items
    }
    
    init(_ items: ArraySlice<T>) {
        self.items.append(contentsOf: items)
    }
    
    var items: [T] = []
}
