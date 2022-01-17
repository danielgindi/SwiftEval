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
