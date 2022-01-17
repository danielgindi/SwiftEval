//
//  Token.swift
//  eyedo agent
//
//  Created by Daniel Cohen Gindi on 16/01/2022.
//

import Foundation
import UIKit

internal class Token {
    init(type: TokenType, position: String.Index) {
        self.type = type
        self.position = position
    }
    
    init(type: TokenType, position: String.Index, value: String?) {
        self.type = type
        self.position = position
        self.value = value
    }
    
    init(type: TokenType, value: String?) {
        self.type = type
        self.value = value
    }
    
    var type: TokenType
    var value: String?
    var position: String.Index?
    var argumentsGroups: ArrayRef<ArrayRef<Token>>?
    var arguments: ArrayRef<Token?>?
    var tokens: ArrayRef<Token>?
    var left: Token?
    var right: Token?
}
