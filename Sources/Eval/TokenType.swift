//
//  TokenType.swift
//  eyedo agent
//
//  Created by Daniel Cohen Gindi on 16/01/2022.
//

import Foundation

internal enum TokenType {
    case string
    case `var`
    case call
    case group
    case number
    case op
    case leftParen
    case rightParen
    case comma
}
