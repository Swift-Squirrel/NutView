//
//  Tokens.swift
//  NutView
//
//  Created by Filip Klembara on 1/27/18.
//

import Foundation

struct Token: CustomStringConvertible, Equatable {

    var id: TokenType
    var value: String
    var line: Int

    enum TokenType: String {
        case leftParentles = "("
        case rightParentles = ")"
        case leftCurly = "{"
        case rightCurly = "}"
        case equal = "="
        case comma = ","
        case text
        case expression
        case namedArgument
    }

    var description: String {
        return "\(line): <\(id.rawValue)> - \(value)"
    }

    // swiftlint:disable:next operator_whitespace
    static func ==(lhs: Token, rhs: Token) -> Bool {
        guard lhs.id == rhs.id else {
            return false
        }
        guard lhs.value == rhs.value else {
            return false
        }
        guard lhs.line == rhs.line else {
            return false
        }
        return true
    }
}

enum NextTokenType {
    case html
    case command
}

struct HTMLToken: Equatable, CustomStringConvertible {
    // swiftlint:disable:next operator_whitespace
    static func ==(lhs: HTMLToken, rhs: HTMLToken) -> Bool {
        guard lhs.value == rhs.value else {
            return false
        }
        guard lhs.line == rhs.line else {
            return false
        }
        return true
    }

    var description: String {
        return "\(line): <html> - \(value)"
    }

    let value: String
    let line: Int
}

struct CommandToken: Equatable, CustomStringConvertible {
    var description: String {
        return "\(line): <\(type.rawValue)>"
    }

    // swiftlint:disable:next operator_whitespace
    static func ==(lhs: CommandToken, rhs: CommandToken) -> Bool {
        guard lhs.type == rhs.type else {
            return false
        }
        guard lhs.line == rhs.line else {
            return false
        }
        return true
    }

    enum CommandTokenType: String {
        case title = "Title"
        case head = "Head"
        case escapedValue = "EscapedValue"
        case rawValue = "RawValue"
        case blockEnd = "}"
        case `else` = "} else {"
        case `elseIf` = "} else if"
        case `if`
        case `for`
        case date = "Date"
        case subview = "Subview"
        case layout = "Layout"
        case view = "View"
    }
    var type: CommandTokenType
    var line: Int
}
