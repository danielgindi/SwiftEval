//
//  CompiledExpression.swift
//  eyedo agent
//
//  Created by Daniel Cohen Gindi on 16/01/2022.
//

import Foundation

public class CompiledExpression {
    internal init(root: Token, configuration: EvalConfiguration) {
        self.root = root
        self.configuration = configuration
    }
    
    internal var root: Token
    public var configuration: EvalConfiguration
    
    public func execute() throws -> Any? {
        return try Evaluator.execute(expression: self)
    }
    
    public func setConstant(name: String, value: Any?) {
        configuration.setConstant(value: value, forName: name)
    }
    
    public func removeConstant(name: String) {
        configuration.removeConstant(name: name)
    }
    
    public func setFunction(name: String, func: @escaping EvalConfiguration.EvalFunctionBlock) {
        configuration.setFunction(func: `func`, forName: name)
    }
    
    public func removeFunction(name: String) {
        configuration.removeFunction(name: name)
    }
    
    public func clearConstants() {
        configuration.clearConstants()
    }
    
    public func clearFunctions() {
        configuration.clearConstants()
    }
}
