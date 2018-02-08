//
//  FruitParser.swift
//  NutView
//
//  Created by Filip Klembara on 8/12/17.
//
//

import SquirrelJSON
import Foundation
import Evaluation

@available(*, deprecated, message: "Use FruitParser")
struct OldFruitParser {
    private let content: String

    init(content: String) {
        self.content = content
    }

    func tokenize() -> OldViewToken {
        // swiftlint:disable:next force_try
        let json = try! JSON(json: content)
        let name = json["fileName"].stringValue
        let body = parse(body: json["body"].arrayValue)
        let head: [OldNutHeadProtocol]
        if let headTokens = json["head"].array {
            head = parse(head: headTokens)
        } else {
            head = []
        }
        let layout = json["layout"]
        let layoutToken: OldLayoutToken?
        if layout["id"].stringValue == "layout" {
            let name = layout["name"].stringValue
            layoutToken = OldLayoutToken(name: name, line: layout["line"].intValue)
        } else {
            layoutToken = nil
        }

        return OldViewToken(name: name, head: head, body: body, layout: layoutToken)
    }

    private func parse(head tokens: [JSON]) -> [OldNutHeadProtocol] {
        var head = [OldNutHeadProtocol]()
        tokens.forEach { (token) in
            switch token["id"].stringValue {
            case "title":
                let expr = parse(expression: token["expression"])
                head.append(OldTitleToken(expression: expr, line: token["line"].intValue))
            default:
                break
            }
        }
        return head
    }

    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity
    private func parse(body tokens: [JSON]) -> [OldNutTokenProtocol] {
        var body = [OldNutTokenProtocol]()
        tokens.forEach({ (token) in
            switch token["id"].stringValue {
            case "text":
                body.append(OldTextToken(value: token["value"].stringValue))
            case "date":
                let date = parse(rawExpression: token["date"])
                let format: OldRawExpressionToken?
                if !token["format"].isNil {
                    format = parse(rawExpression: token["format"])
                } else {
                    format = nil
                }
                body.append(OldDateToken(date: date, format: format, line: token["line"].intValue))
            case "for in Array":
                var forIn = OldForInToken(
                    variable: token["variable"].stringValue,
                    array: token["array"].stringValue,
                    line: token["line"].intValue)

                forIn.setBody(body: parse(body: token["body"].arrayValue))
                body.append(forIn)
            case "for in Dictionary":
                var forIn = OldForInToken(
                    key: token["key"].stringValue,
                    variable: token["variable"].stringValue,
                    array: token["array"].stringValue,
                    line: token["line"].intValue)

                forIn.setBody(body: parse(body: token["body"].arrayValue))
                body.append(forIn)
            case "expression":
                body.append(parse(expression: token))
            case "raw expression":
                body.append(parse(rawExpression: token))
            case "if":
                var ifToken = OldIfToken(
                    condition: parse(rawExpression: token["condition"]),
                    line: token["line"].intValue)

                ifToken.setThen(body: parse(body: token["then"].arrayValue))
                if let elseBlock = token["else"].array {
                    ifToken.setElse(body: parse(body: elseBlock))
                }
                body.append(ifToken)
            case "if let":
                var ifToken = OldIfToken(
                    variable: token["variable"].stringValue,
                    condition: parse(rawExpression: token["condition"]),
                    line: token["line"].intValue)

                ifToken.setThen(body: parse(body: token["then"].arrayValue))
                if let elseBlock = token["else"].array {
                    ifToken.setElse(body: parse(body: elseBlock))
                }
                body.append(ifToken)
            case "view":
                body.append(OldInsertViewToken(line: token["line"].intValue))
            case "subview":
                body.append(OldSubviewToken(
                    name: token["name"].stringValue,
                    line: token["line"].intValue))
            default:
                break
            }
        })
        return body
    }
    // swiftlint:enable function_body_length
    // swiftlint:enable cyclomatic_complexity

    private func parse(expression token: JSON) -> OldExpressionToken {
        return OldExpressionToken(
            infix: token["infix"].stringValue,
            line: token["line"].intValue)
    }
    private func parse(rawExpression token: JSON) -> OldRawExpressionToken {
        return OldRawExpressionToken(
            infix: token["infix"].stringValue,
            line: token["line"].intValue)
    }
}
