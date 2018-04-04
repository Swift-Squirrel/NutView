//
//  NutError.swift
//  NutView
//
//  Created by Filip Klembara on 8/12/17.
//
//

import SquirrelCore
import Evaluation

/// Parser error
public struct NutParserError: SquirrelError {
    /// Error kinds
    ///
    /// - incompleteCommand: Command is incomplete
    /// - syntaxError: syntax error
    /// - lexical: error caused by lexical error
    /// - unknownError: error caused by error from different library
    public enum ErrorKind {
        case incompleteCommand(expecting: String)
        case syntaxError(context: String, line: Int)
        case lexical(error: NutLexical.LexicalError)
        case unknownError(cousingError: Error)
    }
    /// File name
    public let name: String
    /// Error kind
    public let kind: ErrorKind
    /// Description of error
    public var description: String {
        let des: String
        switch kind {
        case .incompleteCommand(let expectation):
            des = "Incomplete command, expecting '\(expectation)' but 'EOF' found"
        case .syntaxError(let contex, let line):
            des = "Syntax error at line: \(line), \(contex)"
        case .lexical(let error):
            des = "Lexical error: \(error.description)"
        case .unknownError(let cousingError):
            des = "Unknown error coused by \(cousingError)"
        }
        return "Error while parsing file \(name), description: \(des)"
    }

    static func incompleteCommand(fileName: String, expecting expectation: String)
        -> NutParserError {

            return NutParserError(name: fileName, kind: .incompleteCommand(expecting: expectation))
    }

    static func syntax(fileName: String, context: String, line: Int) -> NutParserError {
        return NutParserError(name: fileName, kind: .syntaxError(context: context, line: line))
    }

    static func lexical(fileName: String, error: NutLexical.LexicalError) -> NutParserError {
        return NutParserError(name: fileName, kind: .lexical(error: error))
    }

    static func unknown(fileName: String, error: Error) -> NutParserError {
        return NutParserError(name: fileName, kind: .unknownError(cousingError: error))
    }
}

struct NutInterpreterError: SquirrelError {
    enum ErrorKind {
        case wrongValue(expecting: String, got: Any)
        case evaluationError(expression: String, error: EvaluationError)
        case recursiveView
    }
    let fileName: String
    let kind: ErrorKind
    let line: Int
    var description: String {
        let desc: String
        switch kind {
        case .evaluationError(let expression, let error):
            desc = "Evaluation error while evaluating '\(expression)', causing error \(error)"
        case .wrongValue(let expectation, let got):
            desc = "Wrong value, expecting '\(expectation)', but got '\(got)'"
        case .recursiveView:
            desc = "View() command used in View or Subview before View has been fully resolved"
        }
        return "Interpret error in \(fileName) at line \(line) - \(desc)"
    }
    static func recursiveView(fileName: String, line: Int) -> NutInterpreterError {
        return NutInterpreterError(fileName: fileName, kind: .recursiveView, line: line)
    }

    static func evaluation(fileName: String,
                           expression: String,
                           causedBy: EvaluationError,
                           line: Int) -> NutInterpreterError {

        return NutInterpreterError(fileName: fileName,
                                   kind: .evaluationError(expression: expression, error: causedBy),
                                   line: line)
    }

    static func wrongValue(fileName: String,
                           expecting: String,
                           got: Any,
                           line: Int) -> NutInterpreterError {

        return NutInterpreterError(fileName: fileName,
                                   kind: .wrongValue(expecting: expecting, got: got), line: line)
    }
}

/// Nut parser errors
public struct OldNutParserError: SquirrelError {
    /// Error kinds
    ///
    /// - unknownInternalError: Something unexpected happened
    /// - unexpectedEnd: Parser expect specific token but EOF found
    /// - unexpectedBlockEnd: Parser does not expect '\}'
    /// - syntaxError: Syntax error
    /// - expressionError: Error while evaluating expression
    /// - missingValue: Missing value for variable
    /// - evaluationError: Error while evaluating expression
    /// - wrongValue: Parser expect different type of fiven value
    /// - wrongSimpleVariable: Parser expect common variable name `[a-zA-Z][a-zA-Z0-9]*`
    /// - wrongChainedVariable: Parser expect dot convention variable name
    ///    `[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9]*)*`
    public enum ErrorKind {
        case unknownInternalError(commandName: String)
        case unexpectedEnd(reading: String)
        case unexpectedBlockEnd
        case syntaxError(expected: [String], got: String)
        case expressionError
        case missingValue(for: String)
        case evaluationError(infix: String, message: String)
        case wrongValue(for: String, expected: String, got: Any)
        case wrongSimpleVariable(name: String, in: String, regex: String)
        case wrongChainedVariable(name: String, in: String, regex: String)
    }
    /// Kind of error
    public let kind: ErrorKind
    /// Name of file
    public var name: String? = nil
    /// line of error
    public let line: Int
    private let _description: String?
    /// Description
    public var description: String {
        var res = ""
        switch kind {
        case .unknownInternalError(let name):
            res = "Internal error on command: \(name)"
        case .unexpectedEnd(let reading):
            res = "Unexpected end of file while reading: \(reading)"
        case .syntaxError(let expected, let got):
            res = """
                Syntax error
                expected:
                    \(expected.compactMap({ "'" + $0 + "'" }).joined(separator: "\n\t"))
                but got:
                    '\(got)'
                """
        case .expressionError:
            res = "Expression error"
        case .evaluationError(let infix, let message):
            res = "Evaluation error in '\(infix)', message: '\(message)'"
        case .missingValue(let name):
            res = "Missing value for \(name)"
        case .wrongValue(let name, let expected, let got):
            res = "Wrong value for \(name), expected: '\(expected)' "
                + "but got '\(String(describing: got))'"
        case .wrongSimpleVariable(let name, let command, let regex):
            res = "Variable name '\(name)' in '\(command)' does not match "
                + "regular expression '\(regex)'"
        case .wrongChainedVariable(let name, let command, let regex):
            res = "Variable name '\(name)' in '\(command)' does not match "
                + "regular expression '\(regex)'"
        case .unexpectedBlockEnd:
            res = "Unexpected '\\}'"
        }
        if let name = self.name {
            res += "\nFile name: \(name)"
        }
        res += "\nLine:\(line)"
        if let desc = _description {
            res += "\nDescription: \(desc)"
        }
        return res
    }

    init(kind: ErrorKind, line: Int, description: String? = nil) {
        self.kind = kind
        self._description = description
        self.line = line
    }
}

/// Error struct for common errors in NutView
public struct NutError: SquirrelError {

    /// Error kinds
    ///
    /// - notExists: File does not exists
    public enum ErrorKind {
        case notExists(name: String)
    }

    /// Kind of error
    public let kind: ErrorKind
    private let _description: String?
    /// Description
    public var description: String {
        var res = ""
        switch kind {
        case .notExists(let name):
            res = "Nut file: \(name) does not exists"
        }

        if let desc = _description {
            res += "\nDescription: \(desc)"
        }
        return res
    }

    init(kind: ErrorKind, description: String? = nil) {
        self.kind = kind
        self._description = description
    }
}

// MARK: - SquirrelHTMLConvertibleError
extension NutError: SquirrelHTMLConvertibleError {

    /// HTML error representation
    public var htmlErrorRepresentation: String {
        switch kind {
        case .notExists(let name):
            return htmlTemplate(
                title: "Nut file does not exists",
                body: "File name: <i>\(name)</i>")
        }
    }
}

extension OldNutParserError: SquirrelHTMLConvertibleError {

    /// HTML error representation
    public var htmlErrorRepresentation: String {
        func temp(title: String?, body: String) -> String {
            let fileName = name ?? "Uknown file"
            let res = """
            <h4>File: <i>\(fileName)</i></h4>
            <h4>Line: \(line)</h4>
            <div>
            \(body)
            </div>
            """
            return htmlTemplate(title: title, body: res)
        }
        let html: String
        switch kind {
        case .evaluationError(let infix, let message):
            let body = "Evaluation error in '\(infix)' (\(message))".escaped
            html = temp(title: "Evaluation error", body: body)
        case .expressionError:
            html = temp(title: "Expression Error", body: "")
        case .missingValue(let name):
            html = temp(title: "Missing value", body: "Missing value for \(name.escaped)")
        case .syntaxError(let expected, let got):
            let body = """
            Expecting one of:
            <ul style="list-style: none">
            \(expected.map({ "<li>\($0.escaped)</li>\n" }))
            </ul>
            But got: '\(got.escaped)'
            """
            html = temp(title: "Syntax Error", body: body)
        case .unexpectedBlockEnd:
            html = temp(title: "Unexpected block end", body: "Unexpected '\\}'".escaped)
        case .unexpectedEnd(let reading):
            html = temp(
                title: "Unexpected end",
                body: ("Unexpected end of file or using another command "
                    + "while reading: '\(reading)'").escaped)
        case .unknownInternalError(let commandName):
            html = temp(
                title: "Unknown internal error",
                body: "Uknown error in '\(commandName)'".escaped)
        case .wrongChainedVariable(let name, let command, let regex):
            html = temp(
                title: "Wrong variable name",
                body: ("Variable '\(name)' in '\(command)' does not match "
                    + "regular expression: \(regex)").escaped)
        case .wrongSimpleVariable(let name, let command, let regex):
            html = temp(
                title: "Wrong variable name",
                body: ("Variable '\(name)' in '\(command)' does not match "
                    + "regular expression: \(regex)").escaped)
        case .wrongValue(let name, let expected, let got):
            html = temp(
                title: "Wrong value",
                body: ("Wrong value for '\(name)', expected type was '\(expected)' "
                    + "but got '\(got)'").escaped)
        }
        return html
    }
}

extension NutParserError: SquirrelHTMLConvertibleError {

    /// HTML error representation
    public var htmlErrorRepresentation: String {
        func temp(title: String?, body: String, line: Int?) -> String {
            let fileName = name
            var res = """
            <h4>File: <i>\(fileName)</i></h4>
            """
            if let line = line {
                res += "<h4>Line: \(line)</h4>\n"
            }
            res += """
            <div>
            \(body)
            </div>
            """
            return htmlTemplate(title: title, body: res)
        }
        let html: String
        switch kind {
        case .incompleteCommand:
            html = temp(title: "Incomplete command", body: description.escaped, line: nil)
        case .syntaxError(let context, let line):
            html = temp(title: "Syntax error", body: "Syntax error: \(context)".escaped, line: line)
        case .lexical(let error):
            switch error {
            case .unexpectedEnd(let expecting):
                html = temp(title: "Unexpected EOF",
                            body: "Unexpected EOF, expecting \(expecting)",
                            line: nil)
            case .unknownCommand(let command, let line):
                html = temp(title: "Unknown command \(command.escaped)",
                            body: "Unknown command <b>'\(command.escaped)'</b>",
                            line: line)
            case .unexpectedCharacter(let expected, let got, let atLine):
                let body = "Unexpected character, expecting: '\(expected) but got \(got)'".escaped
                html = temp(title: "Unexpected character \(got.description.escaped)",
                            body: body,
                            line: atLine)
            }
        case .unknownError:
            html = temp(title: "Unknown error", body: description, line: nil)
        }
        return html
    }
}

extension NutInterpreterError: SquirrelHTMLConvertibleError {

    /// HTML error representation
    public var htmlErrorRepresentation: String {
        func temp(title: String?, body: String) -> String {
            let res = """
            <h4>File: <i>\(fileName)</i></h4>
            <h4>Line: \(line)</h4>
            <div>
            \(body)
            </div>
            """
            return htmlTemplate(title: title, body: res)
        }
        let html: String
        switch kind {
        case .wrongValue(let expecting, let got):
            let body = "Wrong value in expression, expecting: <i>'\(expecting.escaped)'</i>"
                + " but got <i>'\(String(describing: got).escaped)'</i>"
            html = temp(title: "Wrong value", body: body)
        case .evaluationError(let expression, let error):
            let body = "Evaluation error while evaluating <i>'\(expression.escaped)'</i>,"
                + " error description: \(error.description.escaped)"
            html = temp(title: "Evaluation error", body: body)
        case .recursiveView:
            let body = "View() command used in View or Subview before View has been fully resolved"
            html = temp(title: "Recursive View()", body: body)
        }
        return html
    }
}
