//
//  Eval.swift
//  eyedo agent
//
//  Created by Daniel Cohen Gindi on 16/01/2022.
//

import Foundation

public class Evaluator {
    public static let ConstProviderDefault: AnyObject = ConstProviderDefaultFallback()

    public class func compile(expression: String, configuration: EvalConfiguration) throws -> CompiledExpression {
        var tokens = try tokenizeExpression(expression: expression, configuration: configuration)
        
        var i: Int
        var end = tokens.count
        
        // Collapse +-
        i = 1
        while i < end {
            let token = tokens[i]
            let prevToken = tokens[i - 1]
            
            if token.type == .op &&
                (token.value == "-" || token.value == "+") &&
                prevToken.type == .op &&
                (prevToken.value == "-" || prevToken.value == "+") {
                if prevToken.value != "+" {
                    if (token.value == "-") {
                        token.value = "+"
                    }
                    else {
                        token.value = "-"
                    }
                }
                
                tokens.remove(at: i - 1)
                end = tokens.count
                
                continue
            }
            
            // When we have something like this: "5*-1", we will move the "-" to be part of the number token.
            if token.type == .number &&
                prevToken.type == .op &&
                (prevToken.value == "-" || prevToken.value == "+") &&
                ((i > 1 && tokens[i - 2].type == .op &&
                !configuration.suffixOperators.contains(tokens[i - 2].value ?? "")) || i == 1) {
                if prevToken.value == "-" {
                    token.value = prevToken.value! + token.value!
                }
                
                tokens.remove(at: i - 1)
                end = tokens.count
                
                continue
            }
            
            i = i + 1
        }
        
        let tokenArray = ArrayRef<Token>(tokens)
        
        // Take care of groups (including function calls)
        i = 0
        while i < end {
            let token = tokenArray.items[i]
            
            if token.type == .leftParen {
                let _ = try groupTokens(tokens: tokenArray, startAt: i)
                end = tokenArray.items.count
                continue
            }
            
            i = i + 1
        }
        
        // Build the tree
        let tree = try buildTree(tokens: tokenArray, configuration: configuration)
        
        return CompiledExpression(root: tree, configuration: configuration)
    }
    
    public class func execute(expression: String, configuration: EvalConfiguration) throws -> Any? {
        return try execute(expression: compile(expression: expression, configuration: configuration))
    }
    
    public class func execute(expression: CompiledExpression) throws -> Any? {
        return try evaluateToken(
            token: expression.root,
            configuration: expression.configuration)
    }
    
    internal class func opAtPosition(expression: String, start: String.Index, configuration: EvalConfiguration) throws -> String? {
        var op: String? = nil
        
        let allOperators = configuration._allOperators
        
        for item in allOperators {
            if op != nil && (op == item || item.count <= op!.count) {
                continue
            }
            
            if expression[start..<expression.index(start, offsetBy: item.count)] == item {
                op = item
            }
        }
        
        return op
    }
    
    internal class func indexOfOpInTokens(tokens: ArrayRef<Token>, op: String) -> Int? {
        for i in 0..<tokens.items.count {
            let token = tokens.items[i]
            if token.type == .op && token.value == op {
                return i
            }
        }
        
        return nil
    }
    
    internal class func lastIndexOfOpInTokens(tokens: ArrayRef<Token>, op: String) -> Int? {
        for i in (0..<tokens.items.count).reversed() {
            let token = tokens.items[i]
            if token.type == .op && token.value == op {
                return i
            }
        }
        
        return nil
    }
    
    internal class func lastIndexOfOpArray(tokens: ArrayRef<Token>, ops: [String], config: EvalConfiguration, matchIndex: inout Int?, match: inout String?) {
        var pos: Int? = nil
        var bestMatch: String? = nil
        
        for i in 0..<ops.count {
            let item = ops[i]
            var opIndex: Int?
            
            if config.rightAssociativeOps.contains(item) {
                opIndex = indexOfOpInTokens(tokens: tokens, op: item)
            }
            else {
                opIndex = lastIndexOfOpInTokens(tokens: tokens, op: item)
            }
            
            if opIndex == nil {
                continue
            }
            
            if pos == nil || opIndex! > pos! {
                pos = opIndex
                bestMatch = item
            }
        }
        
        matchIndex = pos
        match = bestMatch
    }
    
    internal class func parseString(data: String, startAt: String.Index, strict: Bool, unquote: Bool, newIndex: inout String.Index) throws -> String {
        var i = startAt
        let endIndex = data.endIndex
        
        var output = ""
        
        var quote: Character = "\0"
        if unquote {
            quote = data[i]
            i = data.index(i, offsetBy: 1)
            
            if quote != "\'" && quote != "\"" {
                throw EvalError.parseError(message: "Not a string")
            }
        }
        
        while i < endIndex {
            var c = data[i]
            
            if c == "\\" {
                if data.index(i, offsetBy: 1) == endIndex {
                    throw EvalError.parseError(message: "Invalid string. An escape character with no escapee encountered at index \(i)")
                }
                
                // Take a step forward here
                
                i = data.index(i, offsetBy: 1)
                c = data[i]
                
                // Test escapee
                
                if c == "\\" ||
                    c == "\'" ||
                    c == "\"" {
                    output.append(c)
                }
                else if c == "b" {
                    output = output + "\u{0008}"
                }
                else if c == "f" {
                    output = output + "\u{000c}"
                }
                else if c == "n" {
                    output = output + "\n"
                }
                else if c == "r" {
                    output = output + "\r"
                }
                else if c == "t" {
                    output = output + "\t"
                }
                else if c == "u" || c == "x" {
                    var uffff: UInt32 = 0
                    let hexSize = c == "u" ? 4 : 2
                    
                    for j in 0..<hexSize {
                        i = data.index(i, offsetBy: 1)
                        c = data[i]
                        
                        var hex: UInt32
                        
                        if c >= "0" && c <= "9" {
                            hex = c.unicodeScalars.first!.value - "0".unicodeScalars.first!.value
                        }
                        else if c >= "a" && c <= "f" {
                            hex = c.unicodeScalars.first!.value - "a".unicodeScalars.first!.value + 10
                        }
                        else if c >= "A" && c <= "F" {
                            hex = c.unicodeScalars.first!.value - "A".unicodeScalars.first!.value + 10
                        }
                        else {
                            if (strict) {
                                throw EvalError.parseError(message: "Unexpected escape sequence at index \(i.utf16Offset(in: data) - j - 2)")
                            }
                            else {
                                i = data.index(i, offsetBy: -1)
                                break
                            }
                        }
                        
                        uffff = uffff * 16 + hex
                    }
                    
                    if let scalar = Unicode.Scalar(uffff) {
                        output.append(Character(scalar))
                    }
                    else {
                        output.append("?")
                    }
                }
                else {
                    if strict {
                        throw EvalError.parseError(message: "Unexpected escape sequence at index \(i.utf16Offset(in: data) - 1)")
                    }
                    else {
                        output.append(c)
                    }
                }
            }
            else if unquote && c == quote {
                newIndex = data.index(i, offsetBy: 1)
                return output
            }
            else {
                output.append(c)
            }
            
            i = data.index(i, offsetBy: 1)
        }
        
        if unquote {
            throw EvalError.parseError(message: "String must be quoted with matching single-quote (') or double-quote(\") characters.")
        }
        
        newIndex = i
        return output
    }
    
    internal class func parseNumber(data: String, startAt: String.Index, newIndex: inout String.Index) throws -> String {
        var i = startAt
        let endIndex = data.endIndex
        
        var exp = 0
        var dec = false
        
        if i >= endIndex {
            throw EvalError.parseError(message: "Can't parse token at \(i.utf16Offset(in: data))")
        }
        
        while i < endIndex {
            let c = data[i]
            
            if (c >= "0" && c <= "9") {
                if exp == 1 || exp == 2 {
                    exp = 3
                }
            }
            else if (c == ".") {
                if dec || exp > 0 { break }
                dec = true
            }
            else if (c == "e") {
                if exp > 0 { break }
                exp = 1
            }
            else if (exp == 1 && (c == "-" || c == "+")) {
                exp = 2
            }
            else {
                break
            }
            
            i = data.index(i, offsetBy: 1)
        }
        
        if (i == startAt || exp == 1 || exp == 2) {
            throw EvalError.parseError(message: "Unexpected character at index \(i.utf16Offset(in: data))")
        }
        
        newIndex = i
        return String(data[startAt..<i])
    }
    
    internal class func tokenizeExpression(expression: String, configuration: EvalConfiguration) throws -> [Token] {
        let varNameChars = configuration.varNameChars
        
        var tokens = [Token]()
        
        if expression.isEmpty { return tokens }
        
        var i = expression.startIndex
        let endIndex = expression.endIndex
        
        while i < endIndex {
            var c = expression[i]
            
            let isDigit = c >= "0" && c <= "9"
            
            if isDigit || c == "." {
                // Starting a number
                var nextIndex: String.Index = i
                let parsedNumber = try parseNumber(data: expression, startAt: i, newIndex: &nextIndex)
                tokens.append(Token(type: .number, position: i, value: parsedNumber))
                i = nextIndex
                continue
            }
            
            var isVarChars = varNameChars.contains(c)
            
            if isVarChars {
                // Starting a variable name - can start only with A-Z_
                
                var token = ""
                
                while i < endIndex {
                    c = expression[i]
                    isVarChars = varNameChars.contains(c)
                    if !isVarChars { break }
                    
                    token.append(c)
                    i = expression.index(i, offsetBy: 1)
                }
                
                tokens.append(Token(type: .var, position: expression.index(i, offsetBy: -token.count), value: token))
                
                continue
            }
            
            if c == "\'" || c == "\"" {
                var nextIndex: String.Index = i
                let parsedString = try parseString(data: expression, startAt: i, strict: false, unquote: true, newIndex: &nextIndex)
                tokens.append(Token(type: .string, position: i, value: parsedString))
                i = nextIndex
                continue
            }
            
            if c == "(" {
                tokens.append(Token(type: .leftParen, position: i))
                i = expression.index(i, offsetBy: 1)
                continue
            }
            
            if c == ")" {
                tokens.append(Token(type: .rightParen, position: i))
                i = expression.index(i, offsetBy: 1)
                continue
            }
            
            if c == "," {
                tokens.append(Token(type: .comma, position: i))
                i = expression.index(i, offsetBy: 1)
                continue
            }
            
            if c == " " || c == "\t" || c == "\u{000c}" || c == "\r" || c == "\n" {
                // Whitespace, skip
                i = expression.index(i, offsetBy: 1)
                continue
            }
            
            if let op = try opAtPosition(expression: expression, start: i, configuration: configuration) {
                tokens.append(Token(type: .op, position: i, value: op))
                i = expression.index(i, offsetBy: op.count)
                continue
            }
            
            throw EvalError.parseError(message: "Unexpected token at index \(i.utf16Offset(in: expression))")
        }
        
        return tokens
    }
    
    internal class func groupTokens(tokens: ArrayRef<Token>, startAt: Int = 0) throws -> Token {
        let isFunc = startAt > 0 && tokens.items[startAt - 1].type == .var
        
        let rootToken = tokens.items[isFunc ? startAt - 1 : startAt]
        
        var groups: ArrayRef<ArrayRef<Token>>? = nil
        var sub: ArrayRef<Token> = ArrayRef<Token>()
        
        if isFunc {
            rootToken.type = .call
            groups = ArrayRef<ArrayRef<Token>>()
            rootToken.argumentsGroups = groups
        }
        else {
            rootToken.type = .group
            rootToken.tokens = sub
        }
        
        var i = startAt + 1
        var end = tokens.items.count
        while i < end {
            let token = tokens.items[i]
            
            if isFunc && token.type == .comma {
                sub = ArrayRef<Token>()
                groups!.items.append(sub)
                i = i + 1
                continue
            }
            
            if token.type == .rightParen {
                if isFunc {
                    tokens.items.removeSubrange(startAt...i)
                }
                else {
                    tokens.items.removeSubrange((startAt+1)...i)
                }
                return rootToken
            }
            
            if token.type == .leftParen {
                let _ = try groupTokens(tokens: tokens, startAt: i)
                end = tokens.items.count
                continue
            }
            
            if isFunc && groups!.items.count == 0 {
                groups!.items.append(sub)
            }
            sub.items.append(token)
            
            i = i + 1
        }
        
        throw EvalError.parseError(message: "Unmatched parenthesis for parenthesis at index \(String(describing: tokens.items[startAt].position))")
    }
    
    internal class func buildTree(tokens: ArrayRef<Token>, configuration: EvalConfiguration) throws -> Token {
        let order = configuration.operatorOrder
        let orderCount = order.count
        let prefixOps = configuration.prefixOperators
        let suffixOps = configuration.suffixOperators
        
        var i = orderCount - 1
        while i >= 0 {
            let cs = order[i]
            
            var pos: Int?
            var op: String?
            lastIndexOfOpArray(tokens: tokens,
                               ops: cs,
                               config: configuration,
                               matchIndex: &pos,
                               match: &op)
            
            guard let pos = pos, let op = op
            else {
                i = i - 1
                continue
            }
            
            let token = tokens.items[pos]
            
            var left: ArrayRef<Token>?
            var right: ArrayRef<Token>?
            
            if prefixOps.contains(op) || suffixOps.contains(op) {
                left = nil
                right = nil
                
                if prefixOps.contains(op) && pos == 0 {
                    right = ArrayRef<Token>(tokens.items[(pos + 1)..<tokens.items.count])
                }
                else if suffixOps.contains(op) && pos > 0 {
                    left = ArrayRef<Token>(tokens.items[0..<pos])
                }
                
                if left == nil && right == nil {
                    throw EvalError.parseError(message: "Operator \(token.value ?? "(null)") is unexpected at index \(String(describing: token.position))")
                }
            }
            else {
                left = ArrayRef<Token>(tokens.items[0..<pos])
                right = ArrayRef<Token>(tokens.items[(pos + 1)..<tokens.items.count])
                
                if left!.items.count == 0 && (op == "-" || op == "+") {
                    left = nil
                }
            }
            
            if (left != nil && left!.items.count == 0) ||
                (right != nil && right!.items.count == 0) {
                throw EvalError.parseError(message: "Invalid expression, missing operand")
            }
            
            if left == nil && op == "-" {
                left = ArrayRef<Token>()
                left?.items.append(Token(type: .number, value: "0"))
            }
            else if left == nil && op == "+" {
                return try buildTree(tokens: right!, configuration: configuration)
            }
            
            if left != nil {
                token.left = try buildTree(tokens: left!, configuration: configuration)
            }
            
            if right != nil {
                token.right = try buildTree(tokens: right!, configuration: configuration)
            }
            
            return token
        }
        
        if tokens.items.count > 1 {
            throw EvalError.parseError(message: "Invalid expression, missing operand or operator at \(String(describing: tokens.items[1].position))")
        }
        
        if tokens.items.count == 0 {
            throw EvalError.parseError(message: "Invalid expression, missing operand or operator.")
        }
        
        var singleToken = tokens.items[0]
        
        if singleToken.type == .group {
            singleToken = try buildTree(tokens: singleToken.tokens!, configuration: configuration)
        }
        else if (singleToken.type == .call) {
            singleToken.arguments = ArrayRef<Token?>()
            for a in 0..<(singleToken.argumentsGroups?.items.count ?? 0) {
                if singleToken.argumentsGroups!.items[a].items.count == 0 {
                    singleToken.arguments?.items.append(nil)
                }
                else {
                    singleToken.arguments?.items.append(
                        try buildTree(tokens: singleToken.argumentsGroups!.items[a],
                                      configuration: configuration)
                    )
                }
            }
        }
        else if singleToken.type == .comma {
            throw EvalError.parseError(message: "Unexpected character at index \(String(describing: singleToken.position))")
        }
        
        return singleToken
    }
    
    internal class func evaluateToken(token: Token, configuration: EvalConfiguration) throws -> Any? {
        let value = token.value
        
        switch token.type {
        case .string:
            return value
            
        case .number:
            if value == nil { return nil }
            
            return configuration.convertToNumber(value!)
            
        case .var:
            
            if value == nil { return nil }
            
            if let provider = configuration.constProvider {
                let val = try provider(value!)
                if val as AnyObject !== ConstProviderDefault {
                    return val
                }
            }
            
            if let constants = configuration.constants {
                if let val = constants[value!] {
                    return val
                }
                
                if let val = constants[value!.uppercased()] {
                    return val
                }
            }
            
            if let val = configuration.genericConstants[value!] {
                return val
            }
            
            if let val = configuration.genericConstants[value!.uppercased()] {
                return val
            }
            
            return nil
            
        case .call:
            return try evaluateFunction(token: token, configuration: configuration)
            
        case .op:
            
            switch token.value {
            case "!": // Factorial or Not
                if token.left != nil { // Factorial (i.e. 5!)
                    return try configuration.factorial(evaluateToken(token: token.left!, configuration: configuration))
                }
                else if token.right != nil { // Not (i.e. !5)
                    return try configuration.logicalNot(evaluateToken(token: token.right!, configuration: configuration))
                }
                
            default:
                guard let left = token.left, let right = token.right else {
                    throw EvalError.parseError(message: "An unexpected error occurred while evaluating expression")
                }
                
                switch token.value {
                case "/": fallthrough // Divide
                case "\\":
                    return try configuration.divide(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case "*": // Multiply
                    return try configuration.multiply(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case "+": // Add
                    return try configuration.add(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case "-": // Subtract
                    return try configuration.subtract(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case "<<": // Shift left
                    return try configuration.bitShiftLeft(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case ">>": // Shift right
                    return try configuration.bitShiftRight(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case "<": // Less than
                    return try configuration.lessThan(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case "<=": // Less than or equals to
                    return try configuration.lessThanOrEqualsTo(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case ">": // Greater than
                    return try configuration.greaterThan(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case ">=": // Greater than or equals to
                    return try configuration.greaterThanOrEqualsTo(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case "==": fallthrough // Equals to
                case "=":
                    return try configuration.equalsTo(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case "!=": fallthrough // Not equals to
                case "<>":
                    return try configuration.notEqualsTo(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case "**": // Power
                    return try configuration.pow(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case "%": // Mod
                    return try configuration.mod(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case "&": // Bitwise AND
                    return try configuration.bitAnd(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case "^": // Bitwise XOR
                    return try configuration.bitXor(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case "|": // Bitwise OR
                    return try configuration.bitOr(a: evaluateToken(token: left, configuration: configuration), b: evaluateToken(token: right, configuration: configuration))
                    
                case "&&": // Logical AND
                    let res = try evaluateToken(token: left, configuration: configuration)
                    if try configuration.isTruthy(res) {
                        return try evaluateToken(token: right, configuration: configuration)
                    }
                    return res
                    
                case "||": // Logical OR
                    let res = try evaluateToken(token: left, configuration: configuration)
                    if try configuration.logicalNot(res) {
                        return try evaluateToken(token: right, configuration: configuration)
                    }
                    return res
                    
                default:
                    break
                }
            }
            
        case .group: break
        case .leftParen: break
        case .rightParen: break
        case .comma: break
        }
        
        throw EvalError.parseError(message: "An unexpected error occurred while evaluating expression")
    }
    
    internal class func evaluateFunction(token: Token, configuration: EvalConfiguration) throws -> Any? {
        let fname = token.value ?? ""
        
        var args = [Any?]()
        
        for arg in token.arguments?.items ?? [] {
            if arg == nil {
                args.append(nil)
            } else {
                args.append(try evaluateToken(token: arg!, configuration: configuration))
            }
        }
        
        var fn = configuration.functions?[fname]
        
        if fn == nil
        {
            fn = configuration.functions?[fname.uppercased()]
        }
        
        if fn == nil
        {
            fn = configuration.genericFunctions[fname]
        }
        
        if fn == nil
        {
            fn = configuration.genericFunctions[fname.uppercased()]
        }
        
        if let fn = fn
        {
            if let val = try fn(args),
               !Optional<Any>.isNone(val) {
                return val
            }
            return nil
        }
        
        throw EvalError.parseError(message: "Function named \"\(fname)\" was not found")
    }
    
    private class ConstProviderDefaultFallback {}
}
