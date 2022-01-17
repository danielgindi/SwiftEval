Eval for Swift
==============

Easily evaluate simple expressions on the go...

This is a port of the [BigEval.js](https://github.com/aviaryan/BigEval.js)/[Eval.net](https://github.com/danielgindi/Eval.net) library
 
Features:
* Evaluate basic math operators (`5 * (4 / 3)`)
* Use constants (`x * 27 / 4`)
* Support for pre-defined function calls (`30 * pow(24, 6) / cos(20)`)
* Support for custom function calls
* Support for logic operators (`26 * 3 < 100` - returns a `bool` value)
* Support for bitwise operators (`(1 << 2) == 4`)
* Support for string values (`"test" + 5 == "test5"`)
* Customize the type that is used for numeric values in the expression.
* Customize the code behind the execution of any of the operators.
* Support for compiling an expression and running multiple times while supplying different constants

### Installation

Just add the repo in Swift Package Manager

### Usage

```
import Eval
        
let config = DoubleEvalConfiguration()

let result1 = try Evaluator.execute("12+45*10", config) as? Double
let result2 = try Evaluator.execute("30 * pow(24, 6) / cos(20)", config) as? Double

let compiled = try Evaluator.compile("5 * n", config.clone())

compiled.setConstant(8, forName: "n")
let result3 = try compiled.execute() as? Double

compiled.setConstant(9, forName: "n")
let result4 = try compiled.execute() as? Double

```

### Operators

The operators currently supported in order of precedence are - 
```js
[
    ['!'],  // Factorial
    ['**'],  // power
    ['/', '*', '%'],
    ['+', '-'],
    ['<<', '>>'],  // bit shifts
    ['<', '<=', '>', '>='],
    ['==', '=', '!='],   // equality comparisons
    ['&'], ['^'], ['|'],   // bitwise operations
    ['&&'], ['||']   // logical operations
]
```

## Me
* Hi! I am Daniel.
* danielgindi@gmail.com is my email address.
* That's all you need to know.

## Help

If you want to buy me a beer, you are very welcome to
[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=8VJRAFLX66N54)
 Thanks :-)

## License

This library is under the Apache License 2.0.

This library is free and can be used in commercial applications without royalty.
