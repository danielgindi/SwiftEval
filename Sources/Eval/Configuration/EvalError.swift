//
//  EvalError.swift
//  eyedo agent
//
//  Created by Daniel Cohen Gindi on 16/01/2022.
//

import Foundation

public enum EvalError: Error {
    case invalidOperation
    case notImplemented
    case parseError(message: String)
}
