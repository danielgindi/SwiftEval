//
//  LogicalProtocol.swift
//  eyedo agent
//
//  Created by Daniel Cohen Gindi on 16/01/2022.
//

import Foundation

public protocol LogicalProtocol {
    func isTruthy(_ a: Any?) throws -> Bool
    func logicalNot(_ a: Any?) throws -> Bool
}
