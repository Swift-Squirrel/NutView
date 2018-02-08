//
//  NutToken.swift
//  NutView
//
//  Created by Filip Klembara on 8/7/17.
//
//

// swiftlint:disable file_length

import Foundation
import Evaluation

@available(*, deprecated, message: "Use without old")
protocol OldNutTokenProtocol {
    var id: String { get }

    var serialized: [String: Any] { get }
}

@available(*, deprecated, message: "Use without old")
protocol OldNutCommandTokenProtocol: OldNutTokenProtocol {
    var line: Int { get }
}

@available(*, deprecated, message: "Use without old")
protocol OldNutViewProtocol: OldNutCommandTokenProtocol {
    var name: String { get }
}

@available(*, deprecated, message: "Use without old")
protocol OldNutSubviewProtocol: OldNutViewProtocol {

}

@available(*, deprecated, message: "Use without old")
protocol OldNutLayoutProtocol: OldNutViewProtocol {

}

@available(*, deprecated, message: "Use without old")
protocol OldNutHeadProtocol: OldNutCommandTokenProtocol {

}

@available(*, deprecated, message: "Use without old")
protocol OldIfTokenProtocol: OldNutCommandTokenProtocol {
    init(condition: String, line: Int) throws
    mutating func setThen(body: [OldNutTokenProtocol])
    mutating func setElse(body: [OldNutTokenProtocol])
    var variable: String? { get }
    var condition: OldRawExpressionToken { get }
}

@available(*, deprecated, message: "Use without old")
struct OldTextToken: OldNutTokenProtocol {
    let id = "text"

    let value: String

    init(value: String) {
        self.value = value
    }

    var serialized: [String: Any] {
        return ["id": id, "value": value]
    }
}

@available(*, deprecated, message: "Use without old")
struct OldInsertViewToken: OldNutCommandTokenProtocol {
    var line: Int

    let id = "view"

    init(line: Int) {
        self.line = line
    }

    var serialized: [String: Any] {
        return ["id": id, "line": line]
    }
}


@available(*, deprecated, message: "Use without old")
struct OldDateToken: OldNutCommandTokenProtocol {
    let line: Int

    let id = "date"

    let date: OldRawExpressionToken

    let format: OldRawExpressionToken?

    init(date: OldRawExpressionToken, format: OldRawExpressionToken? = nil, line: Int) {
        self.date = date
        self.line = line
        self.format = format
    }

    var serialized: [String : Any] {
        var res: [String: Any] = [
            "id": id,
            "date": date.serialized,
            "line": line
        ]
        if let format = self.format {
            res["format"] = format.serialized
        }
        return res
    }
}


@available(*, deprecated, message: "Use without old")
struct OldIfToken: OldNutCommandTokenProtocol, OldIfTokenProtocol {
    private let _id: IDNames

    var id: String {
        return _id.rawValue
    }

    enum IDNames: String {
        case `if`
        case `ifLet` = "if let"
    }

    let line: Int

    let condition: OldRawExpressionToken

    var thenBlock = [OldNutTokenProtocol]()

    var elseBlock: [OldNutTokenProtocol]? = nil

    mutating func setThen(body: [OldNutTokenProtocol]) {
        self.thenBlock = body
    }

    mutating func setElse(body: [OldNutTokenProtocol]) {
        self.elseBlock = body
    }

    let variable: String?

    init(condition: String, line: Int) throws {
        let expected = [
            "if <expression: Bool> {",
            "if let <variableName: Any> = <expression: Any?> {"
        ]
        let exprCondition: String
        let variable: String?
        if condition.hasPrefix("let ") {
            var separated = condition.components(separatedBy: " ")
            guard separated.count == 4 else {
                throw OldNutParserError(
                    kind: .syntaxError(expected: expected, got: "if " + condition + " {"),
                    line: line)
            }
            guard separated[2] == "=" else {
                throw OldNutParserError(
                    kind: .syntaxError(expected: expected, got: "if " + condition + " {"),
                    line: line)
            }
            variable = separated[1]
            separated.removeFirst(3)
            exprCondition = separated.joined(separator: " ")

        } else {
            exprCondition = condition
            variable = nil

        }
        let expr = OldRawExpressionToken(infix: exprCondition, line: line)

        self.init(variable: variable, condition: expr, line: line)
        try checkVariable()
    }

    init(variable: String? = nil, condition: OldRawExpressionToken, line: Int) {
        if let variable = variable {
            self._id = IDNames.ifLet
            self.variable = variable
        } else {
            self._id = IDNames.if
            self.variable = nil
        }
        self.line = line
        self.condition = condition
    }

    func checkVariable() throws {
        if let variable = variable {
            guard VariableCheck.checkSimple(variable: variable) else {
                throw OldNutParserError(
                    kind: .wrongSimpleVariable(
                        name: variable,
                        in: "if let \(variable) = \(condition.infix) {",
                        regex: VariableCheck.simpleVariable.regex),
                    line: line)
            }
            guard VariableCheck.checkChained(variable: condition.infix) else {
                throw OldNutParserError(
                    kind: .wrongChainedVariable(
                        name: condition.infix,
                        in: "if let \(variable) = \(condition.infix) {",
                        regex: VariableCheck.chainedVariable.regex),
                    line: line)
            }
        }
    }

    var serialized: [String: Any] {
        var res: [String: Any] = [
            "id": id,
            "condition": condition.serialized,
            "then": thenBlock.map({ $0.serialized }),
            "line": line
        ]
        if let variable = self.variable {
            res["variable"] = variable
        }
        if let elseBlock = self.elseBlock {
            res["else"] = elseBlock.map({ $0.serialized })
        }
        return res
    }
}

@available(*, deprecated, message: "Use without old")
struct OldElseIfToken: OldNutCommandTokenProtocol, OldIfTokenProtocol {
    enum IDNames: String {
        case elseIf = "else if"
        case elseIfLet = "else if let"
    }

    private let _id: IDNames

    var id: String {
        return _id.rawValue
    }

    let line: Int

    let condition: OldRawExpressionToken

    private var thenBlock = [OldNutTokenProtocol]()

    private var elseBlock: [OldNutTokenProtocol]? = nil

    func getElse() -> [OldNutTokenProtocol]? {
        return elseBlock
    }

    func getThen() -> [OldNutTokenProtocol] {
        return thenBlock
    }

    func getCondition() -> OldRawExpressionToken {
        return condition
    }

    mutating func setThen(body: [OldNutTokenProtocol]) {
        self.thenBlock = body
    }

    mutating func setElse(body: [OldNutTokenProtocol]) {
        self.elseBlock = body
    }

    let variable: String?

    private let expected = [
        "} else if <expression: Bool> {",
        "} else if let <variableName: Any> = <expression: Any?> {"
    ]

    init(condition: String, line: Int) throws {
        let exprCon: String
        if condition.hasPrefix("let ") {
            var separated = condition.components(separatedBy: " ")
            guard separated.count == 4 else {
                throw OldNutParserError(
                    kind: .syntaxError(
                        expected: expected,
                        got: "} else if \(condition) {"),
                    line: line)
            }
            guard separated[2] == "=" else {
                throw OldNutParserError(
                    kind: .syntaxError(
                        expected: expected,
                        got: "} else if \(condition) {"),
                    line: line)
            }
            variable = separated[1]
            separated.removeFirst(3)
            exprCon = separated.joined(separator: " ")
            _id = IDNames.elseIfLet
        } else {
            exprCon = condition
            variable = nil
            _id = IDNames.elseIf
        }
        let expr = OldRawExpressionToken(infix: exprCon, line: line)
        self.condition = expr
        self.line = line
        try checkVariable()
    }

    func checkVariable() throws {
        if let variable = variable {
            guard VariableCheck.checkSimple(variable: variable) else {
                throw OldNutParserError(
                    kind: .wrongSimpleVariable(
                        name: variable,
                        in: "} else if let \(variable) = \(condition.infix) {",
                        regex: VariableCheck.simpleVariable.regex),
                    line: line)
            }
            guard VariableCheck.checkChained(variable: condition.infix) else {
                throw OldNutParserError(
                    kind: .wrongChainedVariable(
                        name: condition.infix,
                        in: "} else if let \(variable) = \(condition.infix) {",
                        regex: VariableCheck.chainedVariable.regex),
                    line: line)
            }
        }
    }

    var serialized: [String: Any] {
        var res: [String: Any] = [
            "id": id,
            "condition": condition.serialized,
            "then": thenBlock.map({ $0.serialized }),
            "line": line
        ]
        if let variable = self.variable {
            res["variable"] = variable
        }
        if let elseBlock = self.elseBlock {
            res["else"] = elseBlock.map({ $0.serialized })
        }
        return res
    }
}

@available(*, deprecated, message: "Use without old")
struct OldLayoutToken: OldNutLayoutProtocol {
    let id = "layout"

    let line: Int

    let name: String

    init(name: String, line: Int) {
        self.line = line
        self.name = name
    }

    var serialized: [String: Any] {
        return ["id": id, "name": name, "line": line]
    }
}

@available(*, deprecated, message: "Use without old")
struct OldSubviewToken: OldNutSubviewProtocol {
    var name: String

    var line: Int

    let id = "subview"

    init(name: String, line: Int) {
        self.line = line
        self.name = name
    }

    var serialized: [String : Any] {
        return ["id": id, "line": line, "name": name]
    }
}

@available(*, deprecated, message: "Use without old")
struct OldTitleToken: OldNutHeadProtocol {
    let id = "title"

    let line: Int

    let expression: OldExpressionToken

    init(expression: OldExpressionToken, line: Int) {
        self.line = line
        self.expression = expression
    }

    var serialized: [String: Any] {
        return ["id": id, "expression": expression.serialized, "line": line]
    }
}

@available(*, deprecated, message: "Use without old")
struct OldForInToken: OldNutCommandTokenProtocol {
    enum IDNames: String {
        case forInArray = "for in Array"
        case forInDictionary = "for in Dictionary"
    }

    private let _id: IDNames
    var id: String {
        return _id.rawValue
    }

    let line: Int

    let variable: String

    let key: String?

    let array: String

    var body: [OldNutTokenProtocol]

    mutating func setBody(body: [OldNutTokenProtocol]) {
        self.body = body
    }

    init(key: String? = nil, variable: String, array: String, line: Int) {
        self.line = line
        if key == nil {
            _id = IDNames.forInArray
        } else {
            _id = IDNames.forInDictionary
        }
        self.key = key
        self.variable = variable
        self.array = array
        self.body = []
    }

    var serialized: [String: Any] {
        var res: [String: Any] = [
            "id": id,
            "variable": variable,
            "array": array,
            "body": body.map({ $0.serialized }),
            "line": line
        ]
        if let key = self.key {
            res["key"] = key
        }
        return res
    }
}

@available(*, deprecated, message: "Use without old")
struct OldElseToken: OldNutCommandTokenProtocol {
    let id = "else"

    let line: Int

    private var body = [OldNutTokenProtocol]()

    init(line: Int) {
        self.line = line
    }

    func getBody() -> [OldNutTokenProtocol] {
        return body
    }

    mutating func setBody(body: [OldNutTokenProtocol]) {
        self.body = body
    }

    var serialized: [String: Any] {
        return ["id": id, "line": line]
    }
}

@available(*, deprecated, message: "Use without old")
struct OldEndBlockToken: OldNutCommandTokenProtocol {
    let id = "}"

    let line: Int

    var serialized: [String: Any] {
        return ["id": id, "line": line]
    }
}
