//
//  EvalConfiguration.swift
//  eyedo agent
//
//  Created by Daniel Cohen Gindi on 16/01/2022.
//

import Foundation

open class EvalConfiguration: MathProtocol,
                              LogicalProtocol,
                              BitwiseProtocol,
                              ComparisonProtocol,
                              ConversionProtocol {
    public typealias EvalFunctionBlock = (_ args: [Any?]) throws -> Any?
    public typealias ConstProvider = (_ varname: String) throws -> Any?
    
    internal var _allOperators = [String]()
    
    private var _operatorOrder = [[String]]()
    
    public var operatorOrder: [[String]] {
        get { return _operatorOrder }
        set {
            _operatorOrder = newValue
            
            var ops = [String]()
            for ops2 in _operatorOrder {
                ops.append(contentsOf: ops2)
            }
            _allOperators = ops
        }
    }
    
    public var prefixOperators = Set<String>()
    public var suffixOperators = Set<String>()
    
    // https://en.wikipedia.org/wiki/Operator_associativity
    public var rightAssociativeOps = Set<String>()
    
    public var varNameChars = Set<Character>()
    
    public var genericConstants = [String: Any?]()
    public var genericFunctions = [String: EvalFunctionBlock]()
    public var constants: [String: Any?]?
    public var functions: [String: EvalFunctionBlock]?

    /**
     * A provider for constants that are not defined in the configuration.
     * This is useful for providing constants that are not known at compile time.
     * Return <code>Evaluator.ConstProviderDefault</code> to fall back to the default behavior.
     */
    public var constProvider: ConstProvider?
    
    public var autoParseNumericStrings: Bool = true
    public var autoParseNumericStringsLocale: Locale? = nil
    
    open func setConstant(value: Any?, forName name: String) {
        if constants == nil {
            constants = [:]
        }
        
        constants![name] = value
    }
    
    open func removeConstant(name: String) {
        if constants == nil { return }
        
        constants?.removeValue(forKey: name)
    }
    
    open func setFunction(func: @escaping EvalFunctionBlock, forName name: String) {
        if functions == nil {
            functions = [String: EvalFunctionBlock]()
        }
        
        functions![name] = `func`
    }
    
    open func removeFunction(name: String) {
        if functions == nil { return }
        
        functions?.removeValue(forKey: name)
    }
    
    open func clearConstants() {
        constants?.removeAll()
    }
    
    open func clearFunctions() {
        functions?.removeAll()
    }
    
    public required init(
        populateDefaults: Bool = true,
        autoParseNumericStrings: Bool = true,
        autoParseNumericStringsLocale: Locale? = nil
    ) {
        self.autoParseNumericStrings = autoParseNumericStrings
        self.autoParseNumericStringsLocale = autoParseNumericStringsLocale
        
        if populateDefaults {
            self.operatorOrder = Defaults.defaultOperatorOrder
            self.prefixOperators = Defaults.defaultPrefixOperators
            self.suffixOperators = Defaults.defaultSuffixOperators
            self.rightAssociativeOps = Defaults.defaultRightAssociativeOps
            self.varNameChars = Defaults.defaultVarNameChars
            self.genericConstants = Defaults.defaultGenericConstants
            self.genericFunctions = Defaults.getDefaultGenericFunctions(
                autoParseNumericStrings: autoParseNumericStrings,
                autoParseNumericStringsLocale: autoParseNumericStringsLocale)
        }
    }
    
    open func clone() -> Self {
        let config = Self(populateDefaults: false,
                          autoParseNumericStrings: autoParseNumericStrings,
                          autoParseNumericStringsLocale: autoParseNumericStringsLocale)
        config.operatorOrder = operatorOrder
        config.prefixOperators = prefixOperators
        config.suffixOperators = suffixOperators
        config.rightAssociativeOps = rightAssociativeOps
        config.varNameChars = varNameChars
        config.genericConstants = genericConstants
        config.genericFunctions = genericFunctions
        config.constants = constants
        config.functions = functions
        config.constProvider = constProvider
        return config
    }
    
    // MARK: - LogicalProtocol
    
    open func isTruthy(_ a: Any?) throws -> Bool {
        if a == nil || Optional<Any>.isNone(a!) {
            return false
        }
        
        if let a = a as? String {
            return a.count > 0
        }
        
        if let a = a as? Bool {
            return a
        }
        
        if let a = a as? NSArray {
            return a.count > 0
        }
        
        if let a = a as? Double {
            return a != 0.0
        }
        
        if let a = a as? Float {
            return a != 0.0
        }
        
        if let a = a as? Decimal {
            return a != 0.0
        }
        
        return true
    }
    
    open func logicalNot(_ a: Any?) throws -> Bool {
        return try !isTruthy(a)
    }
    
    // MARK: - ComparisonProtocol
    
    open func compare(a: Any?, b: Any?) -> ComparisonResult? {
        let aNil = a == nil || Optional<Any>.isNone(a!)
        let bNil = b == nil || Optional<Any>.isNone(b!)
        
        if aNil && bNil { return .orderedSame }
        if aNil { return .orderedAscending }
        if bNil { return .orderedDescending }
        
        if a is Double && b is Double {
            let a = a as! Double
            let b = b as! Double
            return a < b ? .orderedAscending : a > b ? .orderedDescending : .orderedSame
        }
        
        if a is Float && b is Float {
            let a = a as! Decimal
            let b = b as! Decimal
            return a < b ? .orderedAscending : a > b ? .orderedDescending : .orderedSame
        }
        
        if a is Decimal && b is Decimal {
            let a = a as! Decimal
            let b = b as! Decimal
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
    
    open func lessThan(a: Any?, b: Any?) -> Bool {
        guard let res = compare(a: a, b: b) else { return false }
        return res == .orderedAscending
    }
    
    open func lessThanOrEqualsTo(a: Any?, b: Any?) -> Bool {
        guard let res = compare(a: a, b: b) else { return false }
        return res == .orderedAscending || res == .orderedSame
    }
    
    open func greaterThan(a: Any?, b: Any?) -> Bool {
        guard let res = compare(a: a, b: b) else { return false }
        return res == .orderedDescending
    }
    
    open func greaterThanOrEqualsTo(a: Any?, b: Any?) -> Bool {
        guard let res = compare(a: a, b: b) else { return false }
        return res == .orderedDescending || res == .orderedSame
    }
    
    open func equalsTo(a: Any?, b: Any?) -> Bool {
        guard let res = compare(a: a, b: b) else { return false }
        return res == .orderedSame
    }
    
    open func notEqualsTo(a: Any?, b: Any?) -> Bool {
        guard let res = compare(a: a, b: b) else { return false }
        return res != .orderedSame
    }
    
    // MARK: - MathProtocol
    
    open func add(a: Any?, b: Any?) throws -> Any? {
        if let a = a as? Double, let b = b as? Double {
            return a + b
        }
        if let a = a as? Float, let b = b as? Float {
            return a + b
        }
        if let a = a as? Decimal, let b = b as? Decimal {
            return a + b
        }
        throw EvalError.notImplemented
    }
    
    open func subtract(a: Any?, b: Any?) throws -> Any? {
        if let a = a as? Double, let b = b as? Double {
            return a - b
        }
        if let a = a as? Float, let b = b as? Float {
            return a - b
        }
        if let a = a as? Decimal, let b = b as? Decimal {
            return a - b
        }
        throw EvalError.notImplemented
    }
    
    open func multiply(a: Any?, b: Any?) throws -> Any? {
        if let a = a as? Double, let b = b as? Double {
            return a * b
        }
        if let a = a as? Float, let b = b as? Float {
            return a * b
        }
        if let a = a as? Decimal, let b = b as? Decimal {
            return a * b
        }
        throw EvalError.notImplemented
    }
    
    open func divide(a: Any?, b: Any?) throws -> Any? {
        if let a = a as? Double, let b = b as? Double {
            return a / b
        }
        if let a = a as? Float, let b = b as? Float {
            return a / b
        }
        if let a = a as? Decimal, let b = b as? Decimal {
            return a / b
        }
        throw EvalError.notImplemented
    }
    
    open func pow(a: Any?, b: Any?) throws -> Any? {
        if let a = a as? Double, let b = b as? Double {
            return Foundation.pow(a, b)
        }
        if let a = a as? Float, let b = b as? Float {
            return Foundation.pow(a, b)
        }
        if let a = a as? Decimal, let b = b as? Decimal {
            return Decimal(Foundation.pow((a as NSNumber).doubleValue, (b as NSNumber).doubleValue))
        }
        throw EvalError.notImplemented
    }
    
    open func factorial(_ n: Any?) throws -> Any? {
        if let n = n as? Double
        {
            var s = 1
            
            for i in 2...(Int(n)) {
                s = s * i
            }
            
            return s
        }
        else if let n = n as? Float
        {
            var s = 1
            
            for i in 2...(Int(n)) {
                s = s * i
            }
            
            return s
        }
        else if let n = n as? Decimal
        {
            var s = 1
            
            for i in 2...(Int(NSDecimalNumber(decimal: n).doubleValue)) {
                s = s * i
            }
            
            return s
        }
        else if let n = n as? Int
        {
            var s = 1
            
            for i in 2...n {
                s = s * i
            }
            
            return s
        }
        
        throw EvalError.notImplemented
    }
    
    open func mod(a: Any?, b: Any?) throws -> Any? {
        if let a = a as? Double, let b = b as? Double {
            return a.truncatingRemainder(dividingBy: b)
        }
        if let a = a as? Float, let b = b as? Float {
            return a.truncatingRemainder(dividingBy: b)
        }
        if let a = a as? Decimal, let b = b as? Decimal {
            return Decimal(
                (a as NSNumber).doubleValue.truncatingRemainder(dividingBy: (b as NSNumber).doubleValue))
        }
        throw EvalError.notImplemented
    }
    
    // MARK: - BitwiseProtocol
    
    open func bitShiftLeft(a: Any?, b: Any?) throws -> Any? {
        throw EvalError.notImplemented
    }
    
    open func bitShiftRight(a: Any?, b: Any?) throws -> Any? {
        throw EvalError.notImplemented
    }
    
    open func bitAnd(a: Any?, b: Any?) throws -> Any? {
        throw EvalError.notImplemented
    }
    
    open func bitXor(a: Any?, b: Any?) throws -> Any? {
        throw EvalError.notImplemented
    }
    
    open func bitOr(a: Any?, b: Any?) throws -> Any? {
        throw EvalError.notImplemented
    }
    
    // MARK: - ConversionProtocol
    
    open func convertToNumber(_ value: Any?) -> Any? {
        if value is Double {
            return value
        }
        
        if value == nil || Optional<Any>.isNone(value!) {
            return convertToNumber(0.0)
        }
        
        if value is String {
            return (StringConversion.optionallyConvertStringToNumber(
                val: value,
                locale: autoParseNumericStringsLocale) as? NSNumber)?.doubleValue ?? 0.0
        }
        
        return (StringConversion.optionallyConvertStringToNumber(
            val: value,
            locale: autoParseNumericStringsLocale) as? NSNumber)?.doubleValue ?? 0.0
    }
}
