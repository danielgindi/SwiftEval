//
//  MathProtocol.swift
//  eyedo agent
//
//  Created by Daniel Cohen Gindi on 16/01/2022.
//

import Foundation

public protocol MathProtocol {
    func add(a: Any?, b: Any?) throws -> Any?
    func subtract(a: Any?, b: Any?) throws -> Any?
    func multiply(a: Any?, b: Any?) throws -> Any?
    func divide(a: Any?, b: Any?) throws -> Any?
    func pow(a: Any?, b: Any?) throws -> Any?
    func factorial(_ n: Any?) throws -> Any?
    func mod(a: Any?, b: Any?) throws -> Any?
}
