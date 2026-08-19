//
//  Optional.swift
//  
//
//  Created by Daniel Cohen Gindi on 16/01/2022.
//

import Foundation

internal extension Optional {
    static func isNone(_ val: Any) -> Bool {
        if case Optional<Any>.none = val {
            return true
        }
        
        return false
    }
}

func unwrapOptional(_ value: Any?) -> Any? {
    guard var current = value else {
        return nil
    }

    while true {
        let mirror = Mirror(reflecting: current)

        guard mirror.displayStyle == .optional else {
            return current
        }

        guard let child = mirror.children.first else {
            return nil
        }

        current = child.value
    }
}
