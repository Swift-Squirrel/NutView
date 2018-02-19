//
//  NutLexical.swift
//  NutView
//
//  Created by Filip Klembara on 1/27/18.
//

import Foundation
import SquirrelCore

protocol LexicalAnalysis: AnyObject {
    func nextTokenType() throws -> NextTokenType?
    func nextHTML() -> HTMLToken
    func nextCommand() throws -> CommandToken?
    func nextToken() -> Token?
    func getNextToken() -> Token?
    func readExpression(until: NutLexical.Buffer.StopChar...)
        throws -> (Token, NutLexical.Buffer.StopChar)
}

/// Lexical analysis
public class NutLexical {
    private var buffer: Buffer

    init(content: String) {
        buffer = Buffer(content: content)
    }
}

extension Character {
    var isWhite: Bool {
        return self == " " || self == "\t" || self == "\n"
    }
}

// MARK: - LexicalAnalysis
extension NutLexical: LexicalAnalysis {

    func nextToken() -> Token? {
        buffer.skipWhite()
        let line = buffer.line
        guard let char = buffer.next() else {
            return nil
        }
        switch char {
        case "(":
            return Token(id: .leftParentles, value: char.description, line: line)
        case ")":
            return Token(id: .rightParentles, value: char.description, line: line)
        case "=":
            return Token(id: .equal, value: char.description, line: line)
        case "{":
            return Token(id: .leftCurly, value: char.description, line: line)
        case "}":
            return Token(id: .rightCurly, value: char.description, line: line)
        case ",":
            return Token(id: .comma, value: char.description, line: line)
        default:
            var result = char.description
            let tokenStarts: [Character] = ["(", ")", "=", "{", "}", ","]
            while let char = buffer.getNext(), !char.isWhite && !tokenStarts.contains(char) {
                if char == ":" {
                    let _ = buffer.next()
                    return Token(id: .namedArgument, value: result, line: line)
                }
                result.append(buffer.next()!)
            }
            return Token(id: .text, value: result, line: line)
        }
    }

    func getNextToken() -> Token? {
        buffer.stashIndex()
        let token = nextToken()
        buffer.popIndex()
        return token
    }

    func getNextNextToken() -> Token? {
        buffer.stashIndex()
        let _ = nextToken()
        let token = nextToken()
        buffer.popIndex()
        return token
    }


    func nextHTML() -> HTMLToken {
        let line = buffer.line
        var emptyLinesCount = 0
        var emptyLines = ""
        while buffer.getNext() == "\n" {
            emptyLines += String(buffer.next()!)
            emptyLinesCount += 1
        }
        let (readValue, _) = buffer.readEOF(until: .backSlash)
        var html = emptyLines + readValue
        while buffer.getNextNext() == "\\" {
            let _ = buffer.next()
            let _ = buffer.next()
            html += "\\\(buffer.readEOF(until: .backSlash).value)"
        }
        return HTMLToken(value: html, line: line + emptyLinesCount)
    }

    func nextTokenType() throws -> NextTokenType? {
        guard let next = buffer.getNext() else {
            return nil
        }
        if next == "\\" {
            guard let nextNext = buffer.getNextNext() else {
                throw LexicalError.unexpectedEnd(expecting: "character")
            }
            if nextNext == "\\" {
                return .html
            } else {
                return .command
            }
        }
        return .html
    }

    func nextCommand() throws -> CommandToken? {
        guard buffer.getNext() == "\\" else {
            return nil
        }
        let _ = buffer.next()
        let line = buffer.line
        let (type, stop) = buffer.readEOF(until: .space, .lf, .leftParentless, .rightCurly)
        if type == "" && stop == .leftParentless {
            return CommandToken(type: .escapedValue, line: line)
        }
        if type == "" && stop == .rightCurly {
            let _ = buffer.next()
            if let els = getNextToken(), els.id == .text && els.value == "else" {
                let _ = nextToken()
                guard let tok = nextToken() else {
                    throw LexicalError.unexpectedEnd(expecting: "'{' or 'if'")
                }
                switch tok.id {
                case .leftCurly:
                    return CommandToken(type: .`else`, line: line)
                case .text:
                    guard tok.value == "if" else {
                        fallthrough
                    }
                    return CommandToken(type: .elseIf, line: line)
                default:
                    throw LexicalError.unknownCommand("\(type) \(els.value) \(tok.value)",
                        line: tok.line)
                }
            } else {
                return CommandToken(type: .blockEnd, line: line)
            }
        }
        guard let cmd = CommandToken.CommandTokenType(rawValue: type) else {
            throw NutLexical.LexicalError.unknownCommand(type, line: line)
        }
        return CommandToken(type: cmd, line: line)
    }

    func readExpression(until stopChars: NutLexical.Buffer.StopChar...)
        throws -> (Token, NutLexical.Buffer.StopChar) {

            buffer.skipWhite()
            let line = buffer.line
            var stop: NutLexical.Buffer.StopChar? = nil
            var result = ""
            var inString = false
            var leftPars = 0
            repeat {
                guard let char = buffer.next() else {
                    let stopCharsDesc = stopChars.map { $0.rawValue.description }
                        .joined(separator: ", ")

                    throw NutLexical.LexicalError.unexpectedEnd(
                        expecting: "one of [\(stopCharsDesc)]")
                }
                if char == "(" {
                    leftPars += 1
                } else if char == ")" {
                    leftPars -= 1
                }
                if !inString {
                    if char == ")" {
                        if stopChars.contains(.rightParentles) && leftPars == -1 {
                            stop = .rightParentles
                        } else {
                            result.append(char.description)
                        }
                    } else if let stopChar = Buffer.StopChar(rawValue: char),
                        stopChars.contains(stopChar) {

                        stop = stopChar
                    } else {
                        result.append(char.description)
                    }
                } else {
                    result.append(char.description)
                }
                if char == "\"" {
                    inString = !inString
                }
            } while stop == nil
            guard !result.isEmpty else {
                throw NutLexical.LexicalError.unexpectedCharacter(expected: "Identifier",
                                                                  got: stop!.rawValue,
                                                                  atLine: buffer.line)
            }
            return (Token(id: .expression, value: result, line: line), stop!)
    }
}

// MARK: - Errors
public extension NutLexical {
    /// Lexical error
    ///
    /// - unexpectedEnd: Unexpected end of file while reading
    /// - unknownCommand: unknown command
    /// - unexpectedCharacter: unexpected character while reading
    public enum LexicalError: SquirrelError {
        case unexpectedEnd(expecting: String)
        case unknownCommand(String, line: Int)
        case unexpectedCharacter(expected: String, got: Character, atLine: Int)

        /// Error description
        public var description: String {
            switch self {
            case .unexpectedEnd(let expecting):
                return "Unexpected end file - expecting \(expecting) but got EOF"
            case .unknownCommand(let command, let line):
                return "Unknown command '\(command)' at line \(line)"
            case .unexpectedCharacter(let expected, let got, let line):
                return "Unexpected character - expecting \(expected) but got \(got) at line \(line)"
            }
        }

    }
}

extension NutLexical {
    struct Buffer: Sequence, IteratorProtocol {

        init(content: String) {
            self.content = ArraySlice(content)
            count = content.count
            line = 1
            index = 0
            indexes = Stack()
        }
        typealias Element = Character
        private let content: ArraySlice<Character>
        private var index: Int
        private let count: Int
        private(set) var line: Int
        private var indexes: Stack<(index: Int, line: Int)>

        mutating func next() -> Element? {
            guard index < content.count else {
                return nil
            }
            if index > content.startIndex && content[index - 1] == StopChar.lf.rawValue {
                line += 1
            }
            let char = content[index]
            index += 1
            return char
        }

        func getNext() -> Element? {
            guard index < count else {
                return nil
            }
            return content[index]
        }

        func getNextNext() -> Element? {
            guard index + 1 < count else {
                return nil
            }
            return content[index + 1]
        }

        mutating func skipWhite() {
            let whiteChars: Set<Character> = ["\n", " ", "\t"]
            while let char = getNext() {
                guard whiteChars.contains(char) else {
                    break
                }
                let _ = next()
            }
        }

        // swiftlint:disable:next nesting
        enum StopChar: Character {
            case backSlash = "\\"
            case lf = "\n"
            case space = " "
            case leftParentless = "("
            case rightParentles = ")"
            case leftCurly = "{"
            case rightCurly = "}"
            case quote = "\""
            case comma = ","
            case colon = ":"
        }

        mutating func read(until stopChars: StopChar..., skipString: Bool = false)
            -> (value: String, stopped: StopChar)? {
                guard let res = read(until: stopChars,
                                     skipString: skipString,
                                     allowEOF: false) else {

                                        return nil
                }
                assert(res.stopped != nil, "Read with allowEOF == false read until EOF")
                return (res.value, res.stopped!)
        }

        mutating func read(until stopChar: StopChar, skipString: Bool = false) -> String? {
            return read(until: stopChar, skipString: skipString)?.value
        }

        mutating func readEOF(until stopChars: StopChar..., skipString: Bool = false)
            -> (value: String, stopped: StopChar?) {

                let res = read(until: stopChars, skipString: skipString, allowEOF: true)
                assert(res != nil, "Read with allowEOF == true returns nil")
                return res!
        }

        private mutating func read(until stopChars: [StopChar],
                                   skipString: Bool = false,
                                   allowEOF: Bool) -> (value: String, stopped: StopChar?)? {
            guard !stopChars.isEmpty else {
                return nil
            }
            stashIndex()
            var stopped: StopChar? = nil
            var inString = false
            var result = ""
            while stopped == nil {
                guard let char = getNext() else {
                    if allowEOF {
                        dropTopIndex()
                        return (result, nil)
                    } else {
                        popIndex()
                        return nil
                    }
                }
                if skipString && char == StopChar.quote.rawValue {
                    inString = !inString
                }
                if let chr = StopChar(rawValue: char), stopChars.contains(chr) && !inString {
                    stopped = chr
                } else {
                    let _ = next()
                    result += char.description
                }
            }
            dropTopIndex()
            return (result, stopped!)
        }
        mutating func stashIndex() {
            indexes.push((index, line))
        }
        private mutating func dropTopIndex() {
            let _ = indexes.pop()
        }
        mutating func popIndex() {
            guard let ind = indexes.pop() else {
                return
            }
            index = ind.index
            line = ind.line
        }
    }
}
