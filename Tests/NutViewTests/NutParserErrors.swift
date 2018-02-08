//
//  NutParserErrors.swift
//  NutViewTests
//
//  Created by Filip Klembara on 9/7/17.
//

import XCTest
@testable import NutView

class NutParserErrors: XCTestCase {

    func testDateTokenErrors() {
        let name = "Views/Main.nut"
        var content = "\n\\Date()"
        var expect = NutParserError.lexical(fileName: name, error: .unexpectedCharacter(expected: "Identifier", got: ")", atLine: 2))

        XCTAssertNil(checkError(for: content, expect: expect), "Date()")

        content = "\n\n\\Date(\"dwa ada - a) fea \n\ne"
        expect = NutParserError.lexical(fileName: name, error: .unexpectedEnd(expecting: "one of [,, )]"))
        XCTAssertNil(checkError(for: content, expect: expect), "Missing string end '\"' in:\n\(content)\n")

        content = "\n\n\\Date(\"dwa ada\",)"
        expect = NutParserError.syntax(fileName: name, context: "Expecting 'namedArgument' but ')' with value ')' found", line: 3)
        XCTAssertNil(checkError(for: content, expect: expect), "Missing 'format' label in:\n\(content)\n")

        content = "\n\\Date(\"dwa ada\",forma:s)"
        expect = NutParserError.syntax(fileName: name, context: "Expecting value 'format' for token 'namedArgument' but '2: <namedArgument> - forma' found", line: 2)
        XCTAssertNil(checkError(for: content, expect: expect), "Unknown overload 'Date(_:forma:)' in:\n\(content)\n")
    }

    func testIfErrors() {
        let name = "Views/Main.nut"
        var content = "\n\\if {"
        var expect = NutParserError.lexical(fileName: name, error: .unexpectedCharacter(expected: "Identifier", got: "{", atLine: 2))
        XCTAssertNil(checkError(for: content, expect: expect), "Empty condition")

        content = "\n\n\n\n\\if let { \\}"
        expect = NutParserError.syntax(fileName: name, context: "Expecting 'text' but '{' with value '{' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "Empty condition")

        content = "\n\n\n\n\\if let asd as = { \\}"
        expect = NutParserError.syntax(fileName: name, context: "Expecting '=' but 'text' with value 'as' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "Wrong param order")

        content = "\n\n\n\n\\if let = asd as { \\}"
        expect = NutParserError.syntax(fileName: name, context: "Expecting 'text' but '=' with value '=' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "Wrong param order")

//        content = "\n\n\n\n\\if let asd == par { \\}"
//        XCTAssertNil(checkError(for: content, expect: expect), "Missing '='")

        content = "\n\n\n\n\\if par \\}"
        expect = NutParserError.lexical(fileName: name, error: .unexpectedEnd(expecting: "one of [{, ,]"))
        XCTAssertNil(checkError(for: content, expect: expect), "Wrong param order")

        content = "\n\n\n\n\\if let asd   = \\}"
        expect = NutParserError.lexical(fileName: name, error: .unexpectedEnd(expecting: "one of [{, ,]"))
        XCTAssertNil(checkError(for: content, expect: expect), "Wrong param order")
    }

    func testElseIfErrors() {
        let name = "Views/Main.nut"
        var content = "\\if a {\n\\} else if {"
        var expect = NutParserError.lexical(fileName: name, error: .unexpectedCharacter(expected: "Identifier", got: "{", atLine: 2))
//        expect.name = name
        XCTAssertNil(checkError(for: content, expect: expect), "Empty condition")

        content = "\\if a {\n\n\n\n\\} else if let { \\}"
        expect = NutParserError.syntax(fileName: name, context: "Expecting 'text' but '{' with value '{' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "Empty condition")

        content = "\\if a {\n\n\n\n\\} else if let asd as = { \\}"
        expect = NutParserError.syntax(fileName: name, context: "Expecting '=' but 'text' with value 'as' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "Wrong param order")

        content = "\\if a {\n\n\n\n\\} else if let = asd as { \\}"
        expect = NutParserError.syntax(fileName: name, context: "Expecting 'text' but '=' with value '=' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "Wrong param order")

        content = "\\if a {\n\n\n\n\\} else if par \\}"
        expect = NutParserError.lexical(fileName: name, error: .unexpectedEnd(expecting: "one of [{, ,]"))
        XCTAssertNil(checkError(for: content, expect: expect), "Wrong param order")

        content = "\\if a {\n\n\n\n\\} else if let asd as = \\}"
        expect = NutParserError.syntax(fileName: name, context: "Expecting '=' but 'text' with value 'as' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "Wrong param order")
    }

    func testLayoutErrors() {
        let name = "Views/Main.nut"
        let content = "\n\\Layout(\"deasd"
        let expect = NutParserError.lexical(fileName: name, error: .unexpectedEnd(expecting: "one of [)]"))
        XCTAssertNil(checkError(for: content, expect: expect), "Missing \" in String")
    }

    func testSubviewErrors() {
        let name = "Views/Main.nut"
        let content = "\n\\Subview(\"deasd"
        let expect = NutParserError.lexical(fileName: name, error: .unexpectedEnd(expecting: "one of [)]"))
        XCTAssertNil(checkError(for: content, expect: expect), "Missing \" in String")
    }

    func testTitleErrors() {
        let name = "Views/Main.nut"
        let content = "\n\\Title(\"deasd"
        let expect = NutParserError.lexical(fileName: name, error: .unexpectedEnd(expecting: "one of [)]"))
        XCTAssertNil(checkError(for: content, expect: expect), "Missing \" in String")
    }

    func testForErrors() {
        let name = "Views/Main.nut"
        var content = "\n\\for "
        var expect = NutParserError.incompleteCommand(fileName: name, expecting: "variable name")
        XCTAssertNil(checkError(for: content, expect: expect), "Missing '{'")

        content = "\n\n\n\n\\for ds ea sd ads s \\} {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting value 'in' for token 'text' but '5: <text> - ea' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "Missing '{'")

        content = "\n\n\n\n\\for ds at blah {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting value 'in' for token 'text' but '5: <text> - at' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "'at' insted of 'in'")

        content = "\n\n\n\n\\for ds in blah 3ra {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting '{' but 'text' with value '3ra' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "for ds in blah 3ra {")

        // next
        content = "\n\n\n\n\\for (ds, as) ea sd ads s \\} {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting value 'in' for token 'text' but '5: <text> - ea' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "Missing '{'")

        content = "\n\n\n\n\\for (ds, as) at blah {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting value 'in' for token 'text' but '5: <text> - at' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "'at' insted of 'in'")

        content = "\n\n\n\n\\for (ds, as) in blah 3ra {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting '{' but 'text' with value '3ra' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "for ds (ds, as) blah 3ra {")

        content = "\n\n\n\n\\for ds,as in blah {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting 'text' but ',' with value ',' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "for ds,as in blah {")

        content = "\n\n\n\n\\for (ds,as in blah {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting ')' but 'text' with value 'in' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "for (ds,as in blah {")

        content = "\n\n\n\n\\for ds,as) in blah {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting 'text' but ',' with value ',' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "for ds,as) in blah {")

        content = "\n\n\n\n\\for ds, as in blah {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting 'text' but ',' with value ',' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "for ds, as in blah {")

        content = "\n\n\n\n\\for (ds, as in blah {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting ')' but 'text' with value 'in' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "for (ds, as in blah {")

        content = "\n\n\n\n\\for ds, as) in blah {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting 'text' but ',' with value ',' found", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "for ds, as) in blah {")
    }

    func testExpressionErrors() {
        let name = "Views/Main.nut"
        var content = "\n\\(asd a"
        var expect = NutParserError.lexical(fileName: name, error: .unexpectedEnd(expecting: "one of [)]"))
        XCTAssertNil(checkError(for: content, expect: expect), "Missing ')'")

        content = "\n\n\n\n\\() \\} {"
        expect = NutParserError.lexical(fileName: name, error: .unexpectedCharacter(expected: "Identifier", got: ")", atLine: 5))
        XCTAssertNil(checkError(for: content, expect: expect), "Empty expression")
    }

    func testRawValueErrors() {
        let name = "Views/Main.nut"
        var content = "\n\\RawValue(asd a"
        var expect = NutParserError.lexical(fileName: name, error: .unexpectedEnd(expecting: "one of [)]"))
        XCTAssertNil(checkError(for: content, expect: expect), "Missing ')'")

        content = "\n\n\n\n\\RawValue() \\} {"
        expect = NutParserError.lexical(fileName: name, error: .unexpectedCharacter(expected: "Identifier", got: ")", atLine: 5))
        XCTAssertNil(checkError(for: content, expect: expect), "Empty expression")
    }

    func testVariableName() {
        let name = "Views/Main.nut"
        var content = "\n\\if let 3a = asd {"
        var expect = NutParserError.syntax(fileName: name, context: "Identifier name can not starts with '3'", line: 2)
        XCTAssertNil(checkError(for: content, expect: expect), "if let '3a'")

        content = "\n\n\n\n\\if let name.da = asd { \\} {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting identifier without nesting", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "if let name'.da' = asd")

        // else if
        content = "\\if a{\n\\} else if let 3a = asd {"
        expect = NutParserError.syntax(fileName: name, context: "Identifier name can not starts with '3'", line: 2)
        XCTAssertNil(checkError(for: content, expect: expect), "} else if let '3a'")

        content = "\\if a {\n\n\n\n\\} else if let name.da = asd { \\} {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting identifier without nesting", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "} else if let name'.da' = asd")

        // for
        content = "\n\n\n\n\\for 4a in sda { \\} {"
        expect = NutParserError.syntax(fileName: name, context: "Identifier name can not starts with '4'", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "for '4a' in sda {")

        content = "\n\n\n\n\\for name.3a in asd3 { \\} {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting identifier without nesting", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "for name'.3a' in asd3 {")

        content = "\n\n\n\n\\for name in asd.3a { \\} {"
        expect = NutParserError.syntax(fileName: name, context: "Identifier name can not starts with '3'", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "for name in asd'.3a' {")

        content = "\n\n\n\n\\for name in 3a { \\} {"
        expect = NutParserError.syntax(fileName: name, context: "Identifier name can not starts with '3'", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "for name in '.3a' {")

        // next
        content = "\n\n\n\n\\for (4a, asd) in sda { \\} {"
        expect = NutParserError.syntax(fileName: name, context: "Identifier name can not starts with '4'", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "for ('4a', asd) in sda {")

        content = "\n\n\n\n\\for (asd, 4a) in sda { \\} {"
        expect = NutParserError.syntax(fileName: name, context: "Identifier name can not starts with '4'", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "for (asd, '4a') in sda {")

        content = "\n\n\n\n\\for (name.3a, asd) in asd3 { \\} {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting identifier without nesting", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "for (name'.3a', asd) in asd3 {")

        content = "\n\n\n\n\\for (asd, name.3a) in asd3 { \\} {"
        expect = NutParserError.syntax(fileName: name, context: "Expecting identifier without nesting", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "for (asd, name'.3a') in asd3 {")
    }

    func testUnexpectedEndIf() {
        let name = "Views/Main.nut"
        var content = "\n\\if let a = asd { asd s"
        var expect = NutParserError.syntax(fileName: name, context: "<if> command is not closed", line: 2)
        XCTAssertNil(checkError(for: content, expect: expect), "if let")

        content = "\n\n\n\n\\if a == b { asd s"
        expect = NutParserError.syntax(fileName: name, context: "<if> command is not closed", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "if")

        content = "\n\n\n\n\\if let a = b { asd\n \\} else { s"
        expect = NutParserError.syntax(fileName: name, context: "<else> command is not closed", line: 6)
        XCTAssertNil(checkError(for: content, expect: expect), "else")

        content = "\n\n\n\n\\if a == b { asd \\} else { s"
        expect = NutParserError.syntax(fileName: name, context: "<else> command is not closed", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "else")


        content = "\n\n\n\n\\if a == b { asd\n\n \n \\} else if b == c { s"
        expect = NutParserError.syntax(fileName: name, context: "<else if> command is not closed", line: 8)
        XCTAssertNil(checkError(for: content, expect: expect), "else if")

        content = "\n\n\n\n\\if a == b { asd \\} else if let b = c { s"
        expect = NutParserError.syntax(fileName: name, context: "<else if> command is not closed", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "else if let")


        content = "\n\n\n\n\\if a == b { asd \\} else if b == c {  a \\} else {\ns"
        expect = NutParserError.syntax(fileName: name, context: "<else> command is not closed", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "else")

        content = "\n\n\n\n\\if a == b { asd \\} else if let b = c {  a \\} else { s"
        expect = NutParserError.syntax(fileName: name, context: "<else> command is not closed", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "else")

        content = "\n\n\n\n\\if a == b { asd \\} \\}"
        expect = NutParserError.syntax(fileName: name, context: "Unexpected block end 'blockEnd'", line: 5)
        XCTAssertNil(checkError(for: content, expect: expect), "unexpected '\\}'")
    }

    func testUnexpectedEndFor() {
        let name = "Views/Main.nut"
        var content = "\\for a in b { asd s"
        var expect = NutParserError.syntax(fileName: name, context: "<for> command is not closed", line: 1)
        XCTAssertNil(checkError(for: content, expect: expect), "for in Array")

        content = "\n\n\n\n\n\n\\for (a, b) in c { \n\nasd s"
        expect = NutParserError.syntax(fileName: name, context: "<for> command is not closed", line: 7)
        XCTAssertNil(checkError(for: content, expect: expect), "for in Dictionary")

        content = "\n\n\n\n\n\n\\for (a, b) in c { asd s \\} \\}"
        expect = NutParserError.syntax(fileName: name, context: "Unexpected block end 'blockEnd'", line: 7)
        XCTAssertNil(checkError(for: content, expect: expect), "Unexpected '\\}'")
    }

    private func checkError(for content: String, expect: NutParserError) -> String? {
        let parser = NutParser(content: content, name: "Views/Main.nut")

        do {
            _ = try parser.getCommands()
            return "No error"
        } catch let error as NutParserError {
            if expect.description == error.description {
                return nil
            } else {
                return "(\"\(error.description)\") is not equal to (\"\(expect.description)\")"
            }
        } catch let error {
            return "(\"\(error)\") is not equal to (\"\(expect.description)\")"
        }
    }

    static let allTests = [
        ("testDateTokenErrors", testDateTokenErrors),
        ("testIfErrors", testIfErrors),
        ("testElseIfErrors", testElseIfErrors),
        ("testLayoutErrors", testLayoutErrors),
        ("testSubviewErrors", testSubviewErrors),
        ("testTitleErrors", testTitleErrors),
        ("testForErrors", testForErrors),
        ("testExpressionErrors", testExpressionErrors),
        ("testRawValueErrors", testRawValueErrors),
        ("testVariableName", testVariableName),
        ("testUnexpectedEndIf", testUnexpectedEndIf),
        ("testUnexpectedEndFor", testUnexpectedEndFor)
    ]
}
