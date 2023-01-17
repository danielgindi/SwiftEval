//
//  Ops.swift
//  eyedo agent
//
//  Created by Daniel Cohen Gindi on 16/01/2022.
//

import Foundation

open class DoubleEvalConfiguration: EvalConfiguration {
    private func filterArg(_ arg: Any?) -> Any? {
        if autoParseNumericStrings {
            return StringConversion.optionallyConvertStringToNumber(
                val: arg,
                locale: autoParseNumericStringsLocale)
        }
        
        return arg
    }
    
    private let stringifyDoubleFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    open override func add(a: Any?, b: Any?) throws -> Any? {
        if let a = a as? String {
            // do not convert them to numbers by mistake.
            // multiplication could be used to cast to numbers.
            var str: String
            if let d = b as? Double {
                let num = NSNumber(value: d)
                str = (stringifyDoubleFormatter.string(from: num) ?? "\(num)")
            } else {
                str = (b == nil ? "" : "\(b!)")
            }
            return a + str
        }
        else if let b = b as? String {
            // do not convert them to numbers by mistake.
            // multiplication could be used to cast to numbers.
            var str: String
            if let d = a as? Double {
                let num = NSNumber(value: d)
                str = (stringifyDoubleFormatter.string(from: num) ?? "\(num)")
            } else {
                str = (a == nil ? "" : "\(a!)")
            }
            return str + b
        }
        
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { return try super.add(a: a, b: b) }
        
        return a + b
    }
    
    open override func subtract(a: Any?, b: Any?) throws -> Any? {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { return try super.subtract(a: a, b: b) }
        return a - b
    }
    
    open override func multiply(a: Any?, b: Any?) throws -> Any? {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { return try super.multiply(a: a, b: b) }
        return a * b
    }
    
    open override func divide(a: Any?, b: Any?) throws -> Any? {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { return try super.divide(a: a, b: b) }
        return a / b
    }
    
    open override func pow(a: Any?, b: Any?) throws -> Any? {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { return try super.pow(a: a, b: b) }
        return Foundation.pow(a, b)
    }
    
    open override func factorial(_ n: Any?) throws -> Any? {
        guard let n = filterArg(n) as? Double else { return try super.factorial(n) }
        
        var s = 1
        
        for i in 2...(Int(n)) {
            s = s * i
        }
        
        return Double(s)
    }
    
    open override func mod(a: Any?, b: Any?) throws -> Any? {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { return try super.mod(a: a, b: b) }
        return a.truncatingRemainder(dividingBy: b)
    }
    
    open override func bitShiftLeft(a: Any?, b: Any?) throws -> Any? {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { throw EvalError.invalidOperation }
        
        return Double((Int64(a)) << (Int(b)))
    }
    
    open override func bitShiftRight(a: Any?, b: Any?) throws -> Any? {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { throw EvalError.invalidOperation }
        
        return Double((Int64(a)) >> (Int(b)))
    }
    
    open override func bitAnd(a: Any?, b: Any?) throws -> Any? {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { throw EvalError.invalidOperation }
        
        return Double((Int64(a)) & (Int64(b)))
    }
    
    open override func bitXor(a: Any?, b: Any?) throws -> Any? {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { throw EvalError.invalidOperation }
        
        return Double((Int64(a)) ^ (Int64(b)))
    }
    
    open override func bitOr(a: Any?, b: Any?) throws -> Any? {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { throw EvalError.invalidOperation }
        
        return Double((Int64(a)) | (Int64(b)))
    }
}
