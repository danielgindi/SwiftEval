//
//  Ops.swift
//  eyedo agent
//
//  Created by Daniel Cohen Gindi on 16/01/2022.
//

import Foundation

open class DoubleEvalConfiguration: EvalConfiguration {
    private static let BASE_NUMBER_LOCALE = Locale(identifier: "en")
    
    private func filterArg(_ arg: Any) -> Any {
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
    
    open override func add(a: Any, b: Any) throws -> Any {
        if a is String {
            // do not convert them to numbers by mistake.
            // multiplication could be used to cast to numbers.
            var str = a as! String
            if let d = b as? Double {
                let num = NSNumber(value: d)
                str = str + (stringifyDoubleFormatter.string(from: num) ?? "\(b)")
            } else {
                str = str + "\(b)"
            }
            return str
        }
        
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { throw EvalError.invalidOperation }
        return a + b
    }
    
    open override func subtract(a: Any, b: Any) throws -> Any {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { throw EvalError.invalidOperation }
        return a - b
    }
    
    open override func multiply(a: Any, b: Any) throws -> Any {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { throw EvalError.invalidOperation }
        return a * b
    }
    
    open override func divide(a: Any, b: Any) throws -> Any {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { throw EvalError.invalidOperation }
        return a / b
    }
    
    open override func pow(a: Any, b: Any) throws -> Any {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { throw EvalError.invalidOperation }
        return Foundation.pow(a, b)
    }
    
    open func factorial(n: Any) throws -> Any {
        guard let n = filterArg(n) as? Double else { throw EvalError.invalidOperation }
        
        var s = 1
        
        for i in 2...(Int(n)) {
            s = s * i
        }
        
        return s
    }
    
    open override func mod(a: Any, b: Any) throws -> Any {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { throw EvalError.invalidOperation }
        return a.truncatingRemainder(dividingBy: b)
    }
    
    open override func compare(a: Any, b: Any) -> ComparisonResult? {
        var aNil = false
        var bNil = false
        
        if Optional<Any>.isNone(a) {
            aNil = true
        }
        if Optional<Any>.isNone(b) {
            bNil = true
        }
        
        if aNil && bNil { return .orderedSame }
        if aNil { return .orderedAscending }
        if bNil { return .orderedDescending }
        
        if a is Double && b is Double {
            let a = a as! Double
            let b = b as! Double
            return a < b ? .orderedAscending : a > b ? .orderedDescending : .orderedSame
        }
        
        if a is Bool && b is Bool {
            let a = a as! Bool
            let b = b as! Bool
            return !a && b ? .orderedAscending : a && !b ? .orderedDescending : .orderedSame
        }
        
        if a is String && b is String {
            let a = a as! String
            let b = b as! String
            return a.compare(b)
        }
        
        if a is Double || b is Double {
            let a =
            (StringConversion.optionallyConvertStringToNumber(
                val: a,
                locale: autoParseNumericStringsLocale) as? NSNumber)?.doubleValue
            let b =
            (StringConversion.optionallyConvertStringToNumber(
                val: b,
                locale: autoParseNumericStringsLocale) as? NSNumber)?.doubleValue
            if a == nil { return nil }
            if b == nil { return nil }
            
            return a! < b! ? .orderedAscending : a! > b! ? .orderedDescending : .orderedSame
        }
        
        return nil
    }
    
    open override func bitShiftLeft(a: Any, b: Any) throws -> Any {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { throw EvalError.invalidOperation }
        
        return Double((Int64(a)) << (Int(b)))
    }
    
    open override func bitShiftRight(a: Any, b: Any) throws -> Any {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { throw EvalError.invalidOperation }
        
        return Double((Int64(a)) >> (Int(b)))
    }
    
    open override func bitAnd(a: Any, b: Any) throws -> Any {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { throw EvalError.invalidOperation }
        
        return Double((Int64(a)) & (Int64(b)))
    }
    
    open override func bitXor(a: Any, b: Any) throws -> Any {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { throw EvalError.invalidOperation }
        
        return Double((Int64(a)) ^ (Int64(b)))
    }
    
    open override func bitOr(a: Any, b: Any) throws -> Any {
        guard let a = filterArg(a) as? Double, let b = filterArg(b) as? Double
        else { throw EvalError.invalidOperation }
        
        return Double((Int64(a)) | (Int64(b)))
    }
}
