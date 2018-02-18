//
//  NutInterpreter.swift
//  NutView
//
//  Created by Filip Klembara on 8/11/17.
//
//

// swiftlint:disable file_length

import Foundation
import Evaluation
import SquirrelCore
import Regex

protocol NutInterpreterProtocol {
    init(view name: String, with data: [String : Any])

    func resolve() throws -> String
}

class NutInterpreter: NutInterpreterProtocol {
    private var currentName: String
    private var data: [String: Any]
    private let resolver: NutResolverProtocol.Type = NutResolver.self
    private let viewName: String

    private var viewContent: String? = nil

    required init(view name: String, with data: [String: Any]) {
        currentName = name
        self.data = data
        viewName = "Views." + name
    }

    func resolve() throws -> String {
        let viewCommands = try resolver.viewCommands(for: viewName)
        do {
            var head: [HeadCommand]
            let descriptor = try run(body: viewCommands.body)
            viewContent = descriptor.content
            head = descriptor.head

            var result: String
            if let layout = descriptor.layout {
                let layoutName = "Layouts.\(layout)"
                let layoutVC = try resolver.viewCommands(for: layoutName)
                let prevName = currentName
                currentName = layoutName
                let desc = try run(body: layoutVC.body)
                currentName = prevName
                head += desc.head
                result = desc.content
            } else {
                result = descriptor.content
            }

            if head.count > 0 {
                let headResult = try run(head: head)

                let headTag = Regex("[\\s\\S]*<head>[\\s\\S]*</head>[\\s\\S]*")
                if headTag.matches(result) {
                    result.replaceFirst(matching: "</head>", with: headResult + "\n</head>")
                } else {
                    let bodyTag = Regex("[\\s\\S]*<body>[\\s\\S]*</body>[\\s\\S]*")
                    if bodyTag.matches(result) {
                        result.replaceFirst(
                            matching: "<body>",
                            with: "<head>\n" + headResult + "\n</head>\n<body>")
                    } else {
                        result = "<!DOCTYPE>\n<html>\n<head>\n" + headResult
                            + "\n</head>\n<body>\n" + result + "\n</body>\n</html>"
                    }
                }
            }
            return result
        } catch var error as OldNutParserError {
            guard error.name == nil else {
                throw error
            }
            error.name = viewCommands.fileName
            throw error
        }
    }

    private func run(head: [HeadCommand]) throws -> String {
        var res = ""
        for token in head {
            switch token {
            case let title as ViewCommands.Title:
                res += try parse(title: title)
            default:
                res += convertToSpecialCharacters(string: "UnknownToken<\(token.id)>\n")
            }
        }
        return res
    }

    struct ViewDescriptor {
        let content: String
        let head: [HeadCommand]
        let layout: String?
    }

    // swiftlint:disable function_body_length
    // swiftlint:disable:next cyclomatic_complexity
    private func run(body: [Command]) throws -> ViewDescriptor {
        // swiftlint:enable function_body_length
        var res = ""
        var heads = [HeadCommand]()
        var layout: String? = nil
        for token in body {
            switch token {
            case let expression as ViewCommands.EscapedValue:
                res += try parse(expression: expression)
            case let expression as ViewCommands.RawValue:
                res += try parse(rawExpression: expression)
            case let forIn as ViewCommands.For:
                let desc = try parse(forIn: forIn)
                heads += desc.head
                res += desc.content
                layout = desc.layout ?? layout
            case let ifToken as ViewCommands.If:
                let desc = try parse(if: ifToken)
                heads += desc.head
                res += desc.content
                layout = desc.layout ?? layout
            case let text as ViewCommands.HTML:
                res += text.value
            case let date as ViewCommands.Date:
                res += try parse(date: date)
            case let insertView as ViewCommands.InsertView:
                guard let viewContent = self.viewContent else {
                    throw NutInterpreterError.recursiveView(fileName: currentName,
                                                            line: insertView.line)
                }
                res += viewContent
            case let subviewToken as ViewCommands.Subview:
                let subviewName = try parse(rawExpression: subviewToken.name)
                let subview = try resolver.viewCommands(for: "Subviews.\(subviewName)")
                let prevName = currentName
                currentName = subviewName
                let desc = try run(body: subview.body)
                currentName = prevName
                res += desc.content
                heads += desc.head
                layout = desc.layout ?? layout
            case let layoutToken as ViewCommands.Layout:
                let layoutName = try parse(rawExpression: layoutToken.name)
                layout = layoutName
            case let title as ViewCommands.Title:
                heads.append(title)
            default:
                res += convertToSpecialCharacters(string: "UnknownToken<\(token.id)>\n")
            }
        }
        return ViewDescriptor(content: res, head: heads, layout: layout)
    }
}


// HTML escapes
extension NutInterpreter {
    fileprivate func convertToSpecialCharacters(string: String) -> String {
        var newString = string
        let char_dictionary = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&apos;", "'")
        ]
        for (escaped_char, unescaped_char) in char_dictionary {
            newString = newString.replacingOccurrences(
                of: unescaped_char,
                with: escaped_char,
                options: NSString.CompareOptions.literal,
                range: nil)
        }
        return newString
    }
}

// Head parsing
extension NutInterpreter {
    fileprivate func parse(title: ViewCommands.Title) throws -> String {
        let expr = try parse(expression: title.expression)
        return "<title>\(expr)</title>"
    }
}

// getValue
extension NutInterpreter {
    fileprivate func unwrap(any: Any, ifNil: Any = "nil") -> Any {

        let mi = Mirror(reflecting: any)
        if let dispStyle = mi.displayStyle {
            switch dispStyle {
            case .optional:
                if mi.children.count == 0 { return ifNil }
                let (_, some) = mi.children.first!
                return some
            default:
                return any
            }
        }
        return any
    }

    fileprivate func getValue(name: String, from data: [String: Any]) -> Any? {
        if name.contains(".") {
            let separated = name.components(separatedBy: ".")
            if separated.count == 2 {
                if separated[1] == "count" {
                    if let arr = data[separated[0]] as? [Any] {
                        return arr.count
                    } else if let dir = data[separated[0]] as? [String: Any] {
                        return dir.count
                    }
                }
            }
            guard let newData = data[separated[0]] as? [String: Any] else {
                return nil
            }
            var seps = separated
            seps.removeFirst()
            return getValue(name: seps.joined(separator: "."), from: newData)
        } else {
            return (data[name] == nil) ? nil : unwrap(any: data[name]!)
        }
    }

}

// Body parsing
extension NutInterpreter {
    private func parse(rawExpression expression: ViewCommands.RawValue) throws -> String {
        do {
            let res = try expression.evaluate(with: data)
            let str = String(describing: unwrap(any: res ?? "nil"))
            return str
        } catch let error as EvaluationError {
            throw OldNutParserError(
                kind: .evaluationError(infix: expression.expression, message: error.description),
                line: expression.line)
        }
    }

    private func parse(expression: ViewCommands.EscapedValue) throws -> String {
        do {
            let res = try expression.evaluate(with: data)
            let str = String(describing: unwrap(any: res ?? "nil"))
            return convertToSpecialCharacters(string: str)
        } catch let error as EvaluationError {
            throw OldNutParserError(
                kind: .evaluationError(infix: expression.expression, message: error.description),
                line: expression.line)
        }
    }

    private func parse(date dateToken: ViewCommands.Date) throws -> String {
        let dateStr = try parse(rawExpression: dateToken.date)
        guard let dateMiliseconds = Double(dateStr) else {
            throw OldNutParserError(
                kind: .wrongValue(for: "Date(_:format:)", expected: "Double", got: dateStr),
                line: dateToken.date.line)
        }
        let format: ViewCommands.RawValue
        if dateToken.format == nil {
            format = ViewCommands.RawValue(expression: "\"\(NutConfig.dateDefaultFormat)\"",
                                           line: dateToken.line)
        } else {
            format = dateToken.format!
        }
        let formatStr = try parse(rawExpression: format)
        let date = Date(timeIntervalSince1970: dateMiliseconds)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatStr
        return dateFormatter.string(from: date)
    }

    private func parse(forIn: ViewCommands.For) throws -> ViewDescriptor {
        guard let arr = getValue(name: forIn.collection, from: data) else {
            throw OldNutParserError(kind: .missingValue(for: forIn.collection), line: forIn.line)

        }
        let prevValue = data[forIn.value]
        var res = ""
        var heads = [HeadCommand]()
        var layout: String? = nil
        if let keyName = forIn.key {
            let prevKey = data[keyName]
            guard let dic = arr as? [String: Any] else {
                throw OldNutParserError(
                    kind: .wrongValue(for: forIn.collection, expected: "[String: Any]", got: arr),
                    line: forIn.line)
            }
            for (key, value) in dic {
                data[forIn.value] = value
                data[keyName] = key
                let desc = try run(body: forIn.commands)
                res += desc.content
                heads += desc.head
                if let descLayout = desc.layout {
                    layout = descLayout
                }
            }
            data[keyName] = prevKey
        } else {
            guard let array = arr as? [Any] else {
                throw OldNutParserError(
                    kind: .wrongValue(for: forIn.collection, expected: "[Any]", got: arr),
                    line: forIn.line)
            }
            for item in array {
                data[forIn.value] = unwrap(any: item)
                let desc = try run(body: forIn.commands)
                res += desc.content
                heads += desc.head
                if let descLayout = desc.layout {
                    layout = descLayout
                }
            }
        }
        data[forIn.value] = prevValue
        return ViewDescriptor(content: res, head: heads, layout: layout)
    }

    // swiftlint:disable function_body_length
    // swiftlint:disable:next cyclomatic_complexity
    private func parse(if ifToken: ViewCommands.If) throws -> ViewDescriptor {
        // swiftlint:enable function_body_length

        for thenBlock in ifToken.thens {
            guard !thenBlock.conditions.isEmpty else {
                continue
            }
            var superCondition = true
            var variables = Array<(key: String, oldValue: Any?)>()
            for cond in thenBlock.conditions {
                switch cond {
                case .simple(let condition):
                    let any: Any?
                    do {
                        any = try condition.expression.evaluate(with: data)
                    } catch let error as EvaluationError {
                        throw NutInterpreterError.evaluation(fileName: currentName,
                                                             expression: condition.expression,
                                                             causedBy: error,
                                                             line: condition.line)
                    }
                    guard let value = any else {
                        throw NutInterpreterError.wrongValue(fileName: currentName,
                                                             expecting: "Bool",
                                                             got: "nil",
                                                             line: condition.line)
                    }
                    guard let bool = value as? Bool else {
                        throw NutInterpreterError.wrongValue(fileName: currentName,
                                                             expecting: "Bool",
                                                             got: value,
                                                             line: condition.line)
                    }
                    superCondition = superCondition && bool
                case .cast(let variable, let condition):
                    let any: Any?
                    do {
                        any = try condition.expression.evaluate(with: data)
                    } catch let error as EvaluationError {
                        throw NutInterpreterError.evaluation(fileName: currentName,
                                                             expression: condition.expression,
                                                             causedBy: error,
                                                             line: condition.line)
                    }
                    if let value = any {
                        variables.append((variable, data[variable]))
                        data[variable] = value
                    } else {
                        superCondition = false
                    }
                }
                guard superCondition else {
                    break
                }
            }
            if superCondition {
                let desc = try run(body: thenBlock.block)
                variables.forEach({ (key, oldValue) in
                    if let oldValue = oldValue {
                        data[key] = oldValue
                    } else {
                        data.removeValue(forKey: key)
                    }
                })
                return desc
            } else {
                variables.forEach({ (key, oldValue) in
                    if let oldValue = oldValue {
                        data[key] = oldValue
                    } else {
                        data.removeValue(forKey: key)
                    }
                })
            }
        }
        if !ifToken.`else`.isEmpty {
            return try run(body: ifToken.`else`)
        }
        return ViewDescriptor(content: "", head: [], layout: nil)
    }
}
