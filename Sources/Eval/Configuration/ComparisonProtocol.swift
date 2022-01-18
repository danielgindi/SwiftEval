//
//  ComparisonProtocol.swift
//  eyedo agent
//
//  Created by Daniel Cohen Gindi on 16/01/2022.
//

import Foundation

public protocol ComparisonProtocol {
    func compare(a: Any?, b: Any?) -> ComparisonResult?
    func lessThan(a: Any?, b: Any?) -> Bool
    func lessThanOrEqualsTo(a: Any?, b: Any?) -> Bool
    func greaterThan(a: Any?, b: Any?) -> Bool
    func greaterThanOrEqualsTo(a: Any?, b: Any?) -> Bool
    func equalsTo(a: Any?, b: Any?) -> Bool
    func notEqualsTo(a: Any?, b: Any?) -> Bool
    func isTruthy(_ a: Any?) throws -> Bool
    func logicalNot(_ a: Any?) throws -> Bool
}
