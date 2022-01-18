//
//  BitwiseProtocol.swift
//  eyedo agent
//
//  Created by Daniel Cohen Gindi on 16/01/2022.
//

import Foundation

public protocol BitwiseProtocol {
    func bitShiftLeft(a: Any?, b: Any?) throws -> Any?
    func bitShiftRight(a: Any?, b: Any?) throws -> Any?
    func bitAnd(a: Any?, b: Any?) throws -> Any?
    func bitXor(a: Any?, b: Any?) throws -> Any?
    func bitOr(a: Any?, b: Any?) throws -> Any?
}
