//
//  Defaults.cs.swift
//  eyedo agent
//
//  Created by Daniel Cohen Gindi on 16/01/2022.
//

import Foundation

struct Defaults {
    fileprivate init() {}
    
    /// <summary>
    /// Ordering of operators
    /// https://en.wikipedia.org/wiki/Order_of_operations#Programming_languages
    /// </summary>
    public static let defaultOperatorOrder: [[String]] = [
        ["!"],
        ["**"],
        ["\\", "/", "*", "%"],
        ["+", "-"],
        ["<<", ">>"],
        ["<", "<=", ">", ">="],
        ["==", "=", "!=", "<>"],
        ["&"],
        ["^"],
        ["|"],
        ["&&"],
        ["||"]
    ]
    
    public static let defaultPrefixOperators: Set<String> = ["!"]
    public static let defaultSuffixOperators: Set<String> = ["!"]
    public static let defaultRightAssociativeOps: Set<String> = ["**"]
    public static let defaultGenericConstants: [String: Any?] = [
        "PI": Double.pi,
        "PI_2": Double.pi / 2.0,
        "LOG2E": Darwin.M_LOG2E,
        "DEG": Double.pi / 180.0,
        "E": Darwin.M_E,
        "INFINITY": Double.infinity,
        "NAN": Double.nan,
        "TRUE": true,
        "FALSE": false,
    ]
    
    public static func getDefaultGenericFunctions(
        autoParseNumericStrings: Bool = true,
        autoParseNumericStringsLocale: Locale? = nil
    ) -> [String: EvalConfiguration.EvalFunctionBlock]
    {
        var argFilter: (_ arg: Any?) -> Any?
        
        if autoParseNumericStrings {
            argFilter = {
                StringConversion.optionallyConvertStringToNumber(val: $0, locale: autoParseNumericStringsLocale)
            }
        }
        else {
            argFilter = { $0 }
        }
        
        return [
            "ABS": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return abs(arg)
            },
            "ACOS": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return acos(arg)
            },
            "ASIN": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return asin(arg)
            },
            "ATAN": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return atan(arg)
            },
            "ATAN2": { args in
                guard args.count == 2,
                      let arg1 = argFilter(args[0]) as? Double,
                      let arg2 = argFilter(args[1]) as? Double
                else { throw EvalError.invalidOperation }
                return atan2(arg1, arg2)
            },
            "CEILING": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return ceil(arg)
            },
            "COS": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return cos(arg)
            },
            "COSH": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return cosh(arg)
            },
            "EXP": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return exp(arg)
            },
            "FLOOR": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return floor(arg)
            },
            "LOG": { args in
                if args.count == 2 {
                    guard let arg1 = argFilter(args[0]) as? Double,
                          let arg2 = argFilter(args[1]) as? Double
                    else { throw EvalError.invalidOperation }
                    return log(arg1) / log(arg2)
                }
                else if args.count == 1 {
                    guard let arg = argFilter(args[0]) as? Double
                    else { throw EvalError.invalidOperation }
                    return log(arg)
                }
                
                throw EvalError.invalidOperation
            },
            "LOG2": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return log2(arg)
            },
            "LOG10": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return log10(arg)
            },
            "MAX": { args in
                guard args.count > 0 else { return nil }
                
                guard var v = argFilter(args[0]) as? Double else { return nil }
                for arg in args {
                    guard let arg = argFilter(arg) as? Double else { return nil }
                    if arg > v {
                        v = arg
                    }
                }
                return v
            },
            "MIN": { args in
                guard args.count > 0 else { return nil }
                
                guard var v = argFilter(args[0]) as? Double else { return nil }
                for arg in args {
                    guard let arg = argFilter(arg) as? Double else { return nil }
                    if arg < v {
                        v = arg
                    }
                }
                return v
            },
            "POW": { args in
                if args.count == 2 {
                    guard let arg1 = argFilter(args[0]) as? Double,
                          let arg2 = argFilter(args[1]) as? Double
                    else { throw EvalError.invalidOperation }
                    return pow(arg1, arg2)
                }
                
                throw EvalError.invalidOperation
            },
            "ROUND": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return round(arg)
            },
            "SIGN": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return arg < 0 ? -1 : arg > 0 ? 1 : 0
            },
            "SIN": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return sin(arg)
            },
            "SINH": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return sinh(arg)
            },
            "SQRT": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return sqrt(arg)
            },
            "TAN": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return tan(arg)
            },
            "TANH": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return tanh(arg)
            },
            "TRUNCATE": { args in
                guard args.count > 0, let arg = argFilter(args[0]) as? Double else { throw EvalError.invalidOperation }
                return trunc(arg)
            },
        ]
    }
    
    public static let defaultVarNameChars: Set<Character> = Set<Character>("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_$")
}
