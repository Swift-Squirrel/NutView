//
//  NutParser.swift
//  NutViewPackageDescription
//
//  Created by Filip Klembara on 1/27/18.
//

class NutParser: NutParserProtocol {

    private let name: String
    private let viewType: ViewType
    private var layout: ViewCommands.Layout?
    private let content: String

    private var commands: ViewCommands?

    required init(content: String, name: String) {
        self.name = name
        self.content = content
        commands = nil
        let type = name.split(separator: "/", maxSplits: 1).first!
        switch type {
        case "Layouts":
            viewType = .layout
        case "Views":
            viewType = .view
        default:
            viewType = .subview
        }
    }

    func getCommands() throws -> ViewCommands {

        if let commands = self.commands {
            return commands
        }
        let body: [Command]
        do {
            body = try parseCommands()
        } catch let lexError as NutLexical.LexicalError {
            throw NutParserError.lexical(fileName: name, error: lexError)
        } catch let parseError as NutParserError {
            throw parseError
        } catch let error {
            throw NutParserError.unknown(fileName: name, error: error)
        }

        let cmds = ViewCommands(name: name, body: body)
        commands = cmds
        return cmds
    }
}

private extension NutParser {
    // swiftlint:disable function_body_length
    // swiftlint:disable:next cyclomatic_complexity
    func parseCommands() throws -> [Command] {
        // swiftlint:enable function_body_length

        // swiftlint:disable:next nesting
        enum ContextType {
            case main
            case `if`(conditions: [ViewCommands.If.ThenBlock.ConditionType], line: Int)
            case elseIf(ifCmd: ViewCommands.If,
                        conditions: [ViewCommands.If.ThenBlock.ConditionType],
                        line: Int)
            case `else`(ifCmd: ViewCommands.If, line: Int)
            case `for`(key: String?, value: String, collection: String, line: Int)
        }

        let lexical: LexicalAnalysis = NutLexical(content: content)
        var context = Stack<(ContextType, [Command])>()
        var body = [Command]()
        var currentContext: ContextType = .main
        while let tokenType = try lexical.nextTokenType() {
            switch tokenType {
            case .html:
                let html = lexical.nextHTML()
                let command = ViewCommands.HTML(value: html.value, line: html.line)
                body.append(command)
            case .command:
                guard let cmd = try lexical.nextCommand() else {
                    throw NutParserError.incompleteCommand(fileName: name,
                                                           expecting: "tokenId.rawValue")
                }
                let line = cmd.line
                switch cmd.type {
                case .title:
                    let title = try parseTitle(lexical: lexical, line: line)
                    body.append(title)
                case .escapedValue:
                    let value = try parseEscapedValue(lexical: lexical)
                    body.append(value)
                case .rawValue:
                    let value = try parseRawValue(lexical: lexical, line: line)
                    body.append(value)
                case .subview:
                    let subview = try parseSubview(lexical: lexical, line: line)
                    body.append(subview)
                case .view:
                    let view = try parseInserView(lexical: lexical, line: line)
                    body.append(view)
                case .date:
                    let date = try parseDate(lexical: lexical, line: line)
                    body.append(date)
                case .`for`:
                    let forData = try parseFor(lexical: lexical)
                    context.push((currentContext, body))
                    currentContext = .`for`(key: forData.key,
                                            value: forData.value,
                                            collection: forData.collection,
                                            line: line)
                    body.removeAll()
                case .`if`:
                    let conditions = try parseIf(lexical: lexical)
                    context.push((currentContext, body))
                    currentContext = .`if`(conditions: conditions, line: line)
                    body.removeAll()
                case .elseIf:
                    switch currentContext {
                    case .`if`(let conditions, let ifLine):
                        let ifCmd = ViewCommands.If(conditions: conditions,
                                                    then: body,
                                                    line: ifLine)
                        let conditions = try parseIf(lexical: lexical)
                        currentContext = .`elseIf`(ifCmd: ifCmd, conditions: conditions, line: line)
                        body.removeAll()
                    case .elseIf(var ifCmd, let conditions, let ifLine):
                        ifCmd.add(conditions: conditions, then: body, line: ifLine)
                        let conditions = try parseIf(lexical: lexical)
                        currentContext = .`elseIf`(ifCmd: ifCmd, conditions: conditions, line: line)
                        body.removeAll()
                    case .main, .`else`, .for:
                        let context = "Missing if <expression> { for closing \(cmd.type)"
                        throw NutParserError.syntax(fileName: name, context: context, line: line)
                    }
                case .blockEnd:
                    let blockCommand: Command
                    switch currentContext {
                    case .main:
                        throw NutParserError.syntax(fileName: name,
                                                    context: "Unexpected block end '\(cmd.type)'",
                                                    line: line)
                    case .`if`(let conditions, let line):
                        blockCommand = ViewCommands.If(conditions: conditions,
                                                       then: body,
                                                       line: line)
                    case .elseIf(var ifCmd, let conditions, let line):
                        ifCmd.add(conditions: conditions, then: body, line: line)
                        blockCommand = ifCmd
                    case .`else`(var ifCmd, _):
                        ifCmd.setElse(body: body)
                        blockCommand = ifCmd
                    case .`for`(let key, let value, let collection, let line):
                        blockCommand = ViewCommands.For(key: key,
                                                        value: value,
                                                        collection: collection,
                                                        commands: body,
                                                        line: line)
                    }
                    (currentContext, body) = context.pop()!
                    if let ifCmd = blockCommand as? ViewCommands.If {
                        guard !(ifCmd.`else`.isEmpty && ifCmd.thens.isEmpty) else {
                            break
                        }
                    } else if let forCmd = blockCommand as? ViewCommands.For {
                        guard !forCmd.commands.isEmpty else {
                            break
                        }
                    }
                    body.append(blockCommand)
                case .`else`:
                    switch currentContext {
                    case .main, .`else`, .for:
                        let context = "Missing if <expression> { for closing \(cmd.type)"
                        throw NutParserError.syntax(fileName: name, context: context, line: line)
                    case .`if`(let conditions, let ifLine):
                        let ifCmd = ViewCommands.If(conditions: conditions,
                                                    then: body,
                                                    line: ifLine)
                        currentContext = .`else`(ifCmd: ifCmd, line: line)
                        body.removeAll()
                    case .elseIf(var ifCmd, let conditions, let ifLine):
                        ifCmd.add(conditions: conditions, then: body, line: ifLine)
                        currentContext = .`else`(ifCmd: ifCmd, line: line)
                        body.removeAll()
                    }
                case .layout:
                    let layout = try parseLayout(lexical: lexical, line: line)
                    body.append(layout)
                }
            }
        }
        switch currentContext {
        case .main:
            break
        case .`if`(_, let line):
            let context = "<if> command is not closed"
            throw NutParserError.syntax(fileName: name, context: context, line: line)
        case .elseIf(_, _, let line):
            let context = "<else if> command is not closed"
            throw NutParserError.syntax(fileName: name, context: context, line: line)
        case .`else`(_, let line):
            let context = "<else> command is not closed"
            throw NutParserError.syntax(fileName: name, context: context, line: line)
        case .for(_, _, _, let line):
            let context = "<for> command is not closed"
            throw NutParserError.syntax(fileName: name, context: context, line: line)
        }
        return body
    }

    func parseFor(lexical: LexicalAnalysis)
        throws -> (key: String?, value: String, collection: String) {

            guard let tok = lexical.nextToken() else {
                throw NutParserError.incompleteCommand(fileName: name, expecting: "variable name")
            }
            let key: String?
            let value: String
            switch tok.id {
            case .text:
                key = nil
                try  check(variable: tok.value, line: tok.line, allowNesting: false)
                value = tok.value
            case .leftParentles:
                let keyToken = try checkNextToken(lexical: lexical, tokenId: .text)
                try check(variable: keyToken.value, line: keyToken.line, allowNesting: false)
                key = keyToken.value
                let _ = try checkNextToken(lexical: lexical, tokenId: .comma)
                let valueToken = try checkNextToken(lexical: lexical, tokenId: .text)
                try check(variable: valueToken.value, line: valueToken.line, allowNesting: false)
                value = valueToken.value
                let _ = try checkNextToken(lexical: lexical, tokenId: .rightParentles)
            default:
                let context = "Expecting 'variable name' or 'tupple' but '\(tok)' found"
                throw NutParserError.syntax(fileName: name, context: context, line: tok.line)
            }
            let _ = try checkNextToken(lexical: lexical, tokenId: .text, expValue: "in")
            let collectionToken = try checkNextToken(lexical: lexical, tokenId: .text)
            try check(variable: collectionToken.value,
                      line: collectionToken.line,
                      allowNesting: true)
            let _ = try checkNextToken(lexical: lexical, tokenId: .leftCurly)
            return (key, value, collectionToken.value)
    }

    func parseIf(lexical: LexicalAnalysis) throws -> [ViewCommands.If.ThenBlock.ConditionType] {
        var stop = NutLexical.Buffer.StopChar.leftCurly
        var conditions = [ViewCommands.If.ThenBlock.ConditionType]()
        repeat {
            guard let letToken = lexical.getNextToken() else {
                throw NutParserError.incompleteCommand(fileName: name,
                                                       expecting: "let or expression")
            }
            let variable: String?
            if letToken.id == .text && letToken.value == "let" {
                let _ = lexical.nextToken()
                let vari = try checkNextToken(lexical: lexical, tokenId: .text)
                try check(variable: vari.value, line: vari.line, allowNesting: false)
                let _ = try checkNextToken(lexical: lexical, tokenId: .equal)
                variable = vari.value
            } else {
                variable = nil
            }
            let (cond, newStop) = try lexical.readExpression(until: .leftCurly, .comma)
//            if newStop == .comma {
//                let _ = try checkNextToken(lexical: lexical, tokenId: .comma)
//            }
            let condition = ViewCommands.RawValue(expression: cond.value, line: cond.line)
            if let variable = variable {
                conditions.append(.cast(variable: variable, condition: condition))
            } else {
                conditions.append(.simple(condition: condition))
            }
            stop = newStop
        } while stop == .comma
        return conditions
    }

    func parseInserView(lexical: LexicalAnalysis, line: Int) throws -> ViewCommands.InsertView {
        let _ = try checkNextToken(lexical: lexical, tokenId: .leftParentles)
        let _ = try checkNextToken(lexical: lexical, tokenId: .rightParentles)

        return ViewCommands.InsertView(line: line)
    }
    func parseSubview(lexical: LexicalAnalysis, line: Int) throws -> ViewCommands.Subview {
        let value = try parseRawValue(lexical: lexical, line: line)
        return ViewCommands.Subview(name: value, line: line)
    }
    func parseLayout(lexical: LexicalAnalysis, line: Int) throws -> ViewCommands.Layout {
        let value = try parseRawValue(lexical: lexical, line: line)
        return ViewCommands.Layout(name: value, line: line)
    }
    func parseRawValue(lexical: LexicalAnalysis, line: Int) throws -> ViewCommands.RawValue {
        let _ = try checkNextToken(lexical: lexical, tokenId: .leftParentles)
        let (expr, _) = try lexical.readExpression(until: .rightParentles)
        return ViewCommands.RawValue(expression: expr.value, line: line)
    }
    func parseEscapedValue(lexical: LexicalAnalysis) throws -> ViewCommands.EscapedValue {
        let _ = try checkNextToken(lexical: lexical, tokenId: .leftParentles)
        let (expr, _) = try lexical.readExpression(until: .rightParentles)
        return ViewCommands.EscapedValue(expression: expr.value, line: expr.line)
    }
    func parseTitle(lexical: LexicalAnalysis, line: Int) throws -> ViewCommands.Title {
        let value = try parseEscapedValue(lexical: lexical)
        return ViewCommands.Title(expression: value, line: line)
    }
    func parseDate(lexical: LexicalAnalysis, line: Int) throws -> ViewCommands.Date {
        let _ = try checkNextToken(lexical: lexical, tokenId: .leftParentles)
        let (expr, stop) = try lexical.readExpression(until: .comma, .rightParentles)
        let formatExp: ViewCommands.RawValue?
        if stop == .comma {
            let _ = try checkNextToken(lexical: lexical,
                                       tokenId: .namedArgument,
                                       expValue: "format")
            let (format, _) = try lexical.readExpression(until: .rightParentles)
            formatExp = ViewCommands.RawValue(expression: format.value, line: format.line)
        } else {
            formatExp = nil
        }
        let exprValue = ViewCommands.RawValue(expression: expr.value, line: expr.line)
        return ViewCommands.Date(date: exprValue, format: formatExp, line: line)
    }

    func checkNextToken(lexical: LexicalAnalysis,
                        tokenId: Token.TokenType,
                        expValue: String? = nil) throws -> Token {

        guard let token = lexical.nextToken() else {
            throw NutParserError.incompleteCommand(fileName: name, expecting: tokenId.rawValue)
        }
        guard token.id == tokenId else {
            let context = "Expecting '\(tokenId.rawValue)'"
                + " but '\(token.id.rawValue)' with value '\(token.value)' found"
            throw NutParserError.syntax(fileName: name, context: context, line: token.line)
        }
        if let expValue = expValue {
            guard token.value == expValue else {
                let context = "Expecting value '\(expValue)' for token '\(tokenId)'"
                    + " but '\(token)' found"
                throw NutParserError.syntax(fileName: name, context: context, line: token.line)
            }
        }
        return token
    }
    func check(variable: String, line: Int, allowNesting: Bool) throws {
        // swiftlint:disable:next nesting
        enum State {
            case start
            case inVariable
        }
        var state: State = .start
        var iterator = variable.makeIterator()
        while let char = iterator.next() {
            switch state {
            case .start:
                switch char {
                case "a"..."z", "A"..."Z", "_":
                    state = .inVariable
                default:
                    let context = "Identifier name can not starts with '\(char)'"
                    throw NutParserError.syntax(fileName: name, context: context, line: line)
                }
            case .inVariable:
                switch char {
                case "a"..."z", "A"..."Z", "0"..."9", "_":
                    break
                case ".":
                    guard allowNesting else {
                        let context = "Expecting identifier without nesting"
                        throw NutParserError.syntax(fileName: name, context: context, line: line)
                    }
                    state = .start
                default:
                    let context = "Unsupported character '\(char)' for identifier"
                    throw NutParserError.syntax(fileName: name, context: context, line: line)
                }
            }
        }
        guard state == .inVariable else {
            let context = "'\(variable)' is not valid identifier"
            throw NutParserError.syntax(fileName: name, context: context, line: line)
        }
    }
}

extension NutParser {
    private enum ViewType {
        case view
        case layout
        case subview
    }
}
