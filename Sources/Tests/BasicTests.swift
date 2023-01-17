//
//  BasicTests.swift
//  
//
//  Created by Daniel Cohen Gindi on 16/01/2022.
//

import Foundation

@testable import Eval
import XCTest

final class BasicTests: XCTestCase {
    func testBasicExpressions() throws {
        
        let config = DoubleEvalConfiguration()

        testExpr("12+45*10", value: 12 + 45 * 10, config: config)

        let d = 12.0 / 4.0 * 5.0 + 45.0 * 13.0 - 72.0 * 598.0
        testExpr("12/4 * 5 + 45*13 - 72 * 598",
                 value: d,
                 config: config)
        
        testExpr("345 / 23 * 124 / 41 * 12",
                 value: 345 / 23 * 124 / 41 * 12,
                 config: config)
       
        testExpr("345 / 23 >> 3 * 124 / 41 * 12", value: Double(Int64(345.0 / 23) >> Int64(3 * 124.0 / 41.0 * 12.0)), config: config)
        
        testExpr("345 / (23 >> 3) * 124 / 41 * 12", value: 345.0 / Double(23 >> 3) * 124.0 / 41.0 * 12.0, config: config)
        
        testExpr("345 / pow(5,12/9) * 124 / 41 * 12", value: 345.0 / pow(5.0, 12.0 / 9.0) * 124.0 / 41.0 * 12.0, config: config)
        
        testExpr("2*5!+3",
                 value: 243,
                 config: config)
                 
        testExpr("-5&&2==7&&-4>=-5>>-8*-5", value: (-5 != 0 && 2 == 7 && -4 >= -5 >> -8 * -5), config: config)
        
        testExpr("\"testing\" == \"testing\"", value: true, config: config)
        
        testExpr("\"testing\"", value: "testing", config: config)
        
        testExpr("\"testing\" + 58.3", value: "testing58.3", config: config)
        
        let withConsts = config.clone()
        withConsts.setConstant(value: 5.9, forName: "x")
        testExpr("x * 27 + (8>>2) / x", value: 5.9 * 27.0 + Double((8 as Int >> 2)) / 5.9, config: withConsts)
        
        testExpr("max(1,5,8.7)", value: 8.7, config: withConsts)
        
        testExpr("30 * PI", value: 30 * Double.pi, config: withConsts)
        
        testExpr("-4^(7**2)**-2", value: -4, config: config)
        
        testExpr("-4^7**(2**-2)", value: -3, config: config)
        
        testExpr("-4^7**2**-2", value: -3, config: config)
        
        testExpr("\"-4\"^7**\"2\"**-2", value: -3, config: config)
        
        testExpr("\"abc\"+5", value: "abc5", config: config)
        
        testExpr("\"5\"+5", value: "55", config: config)
        
        testExpr("12e5", value: 1200000, config: config)
        
        testExpr("12e+5", value: 1200000, config: config)
        
        withConsts.constProvider = {
            if $0 == "y" {
                return 5.0
            }
            
            return Evaluator.ConstProviderDefault
        }
        
        testExpr("x", value: 5.9, config: withConsts)
        testExpr("y", value: 5.0, config: withConsts)
        
        withConsts.constProvider = {
            if $0 == "y" {
                return 5.0
            }
            
            return nil
        }
        
        testExpr("x", value: nil as Double?, config: withConsts)
        testExpr("y", value: 5.0, config: withConsts)
    }
    
    private func testExpr(_ expr: String, value: Double?, config: EvalConfiguration)
    {
        XCTAssertEqual(
            try Evaluator.execute(expression: expr, configuration: config) as? Double,
            value)
    }
    
    private func testExpr(_ expr: String, value: Bool?, config: EvalConfiguration)
    {
        XCTAssertEqual(
            try Evaluator.execute(expression: expr, configuration: config) as? Bool,
            value)
    }
    
    private func testExpr(_ expr: String, value: String?, config: EvalConfiguration)
    {
        XCTAssertEqual(
            try Evaluator.execute(expression: expr, configuration: config) as? String,
            value)
    }
}
