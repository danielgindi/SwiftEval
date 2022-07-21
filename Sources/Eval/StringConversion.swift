//
//  StringConversion.swift
//  eyedo agent
//
//  Created by Daniel Cohen Gindi on 16/01/2022.
//

import Foundation

public class StringConversion {
    public class func guessNumberComma(val: String) -> Bool {
        let sval = val.trimmingCharacters(in: .whitespacesAndNewlines)
        let p1 = val.firstIndex(of: ".")
        let p2 = p1 == nil ? nil : val.lastIndex(of: ".")
        let c1 = sval.firstIndex(of: ",")
        let c2 = c1 == nil ? nil : val.lastIndex(of: ",")
        let hasSign = val.count > 0 && (sval.hasPrefix("-") || sval.hasPrefix("+"))
        let lenNoSign = hasSign ? val.count - 1 : val.count
        
        var isCommaBased: Bool = false
        
        if c1 != nil && p1 != nil {  // who's last?
            isCommaBased = c2! > p2!
        } else if c1 != c2 {  // two commas, must be thousands
            isCommaBased = false
        } else if p1 != p2 {  // two periods, must be thousands
            isCommaBased = true
        } else if c2 != nil && (lenNoSign > 7 || lenNoSign < 5) {  // there is a comma, but it could not be thousands as there should be more than one
            isCommaBased = true
        } else if p2 != nil && (lenNoSign > 7 || lenNoSign < 5) {  // there is a period, but it could not be thousands as there should be more than one
            isCommaBased = false
        } else if c1 != nil && c2! != sval.index(sval.endIndex, offsetBy: -4) {  // comma not in thousands position
            isCommaBased = true
        } else if p1 != nil && p2! != sval.index(sval.endIndex, offsetBy: -4) {  // period not in thousands position
            isCommaBased = false
        }
        
        return isCommaBased
    }
    
    private static let COMMA_BASED_FORMATTER: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "es")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    private static let PERIOD_BASED_FORMATTER: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    public class func optionallyConvertStringToNumber(val: Any?, locale: Locale? = nil) -> Any? {
        if let sval = val as? String {
            var formatter: NumberFormatter
            
            if locale != nil {
                formatter = NumberFormatter()
                formatter.locale = locale
                formatter.numberStyle = .decimal
                formatter.usesGroupingSeparator = true
            } else {
                formatter =
                guessNumberComma(val: sval)
                ? COMMA_BASED_FORMATTER : PERIOD_BASED_FORMATTER
            }
            
            if let number = formatter.number(from: sval) {
                return number as AnyObject
            }
            
            if locale != nil {
                formatter =
                guessNumberComma(val: sval)
                ? COMMA_BASED_FORMATTER : PERIOD_BASED_FORMATTER
                
                if let number = formatter.number(from: sval) {
                    return number as AnyObject
                }
            }
            
            return val
        } else {
            return val
        }
    }
}
