//
//  LexicalTests.swift
//  NutViewTests
//
//  Created by Filip Klembara on 1/27/18.
//

import XCTest
@testable import NutView

class LexicalTests: XCTestCase {
    func testSimple() {
//        let cnt =  """
//            as
//            \\Title("Title) of ((post) a )")
//            this is about \\(_topic)
//            """
//        let lex: LexicalAnalysis = NutLexical(content: cnt)
//        guard let type1 = try? lex.nextTokenType() else {
//            XCTFail("EOF")
//            return
//        }
//        XCTAssertNotNil(type1)
//        XCTAssertTrue(type1 == .html)
//        let html1 = lex.nextHTML()
//        let expHTML1 = HTMLToken(value: "as\n", line: 1)
//        XCTAssertEqual(expHTML1, html1)
//
//        guard let type2 = try? lex.nextTokenType() else {
//            XCTFail("EOF")
//            return
//        }
//        XCTAssertNotNil(type2)
//        XCTAssertTrue(type2 == .command)
//        guard let cmd1 = try? lex.nextCommand() else {
//            XCTFail()
//            return
//        }
//        XCTAssertNotNil(cmd1)
//        let expCmd1 = CommandToken(type: .title, line: 2)
//        XCTAssertEqual(expCmd1, cmd1)
//
//        guard let par1 = try? lex.nextParentleses() else {
//            XCTFail()
//            return
//        }
//        let expPar1 = Parethleses(value: "\"Title) of ((post) a )\"", line: 2)
//        XCTAssertEqual(expPar1, par1)
//
//        guard let type3 = try? lex.nextTokenType() else {
//            XCTFail("EOF")
//            return
//        }
//        XCTAssertNotNil(type3)
//        XCTAssertTrue(type3 == .html)
//        let html2 = lex.nextHTML()
//        let expHTML2 = HTMLToken(value: "\nthis is about ", line: 3)
//        XCTAssertEqual(expHTML2, html2)
//
//        guard let type4 = try? lex.nextTokenType() else {
//            XCTFail("EOF")
//            return
//        }
//        XCTAssertNotNil(type4)
//        XCTAssertTrue(type4 == .command)
//        guard let cmd2 = try? lex.nextCommand() else {
//            XCTFail()
//            return
//        }
//        XCTAssertNotNil(cmd2)
//        let expCmd2 = CommandToken(type: .escapedValue, line: 3)
//        XCTAssertEqual(expCmd2, cmd2)
//
//        guard let par2 = try? lex.nextParentleses() else {
//            XCTFail()
//            return
//        }
//        let expPar2 = Parethleses(value: "_topic", line: 3)
//        XCTAssertEqual(expPar2, par2)
//        guard let nilik = try? lex.nextTokenType() else {
//            XCTFail()
//            return
//        }
//        XCTAssertNil(nilik)
    }

    func testCommented() {
        let cnt = """
            asd
            \\\\\\\\das\\View
            """
        let lex: LexicalAnalysis = NutLexical(content: cnt)
        guard let type = try? lex.nextTokenType() else {
            XCTFail()
            return
        }
        XCTAssertNotNil(type)
        XCTAssertTrue(type == .html)
        let html = lex.nextHTML()
        let expHTML = HTMLToken(value: "asd\n\\\\das", line: 1)
        XCTAssertEqual(expHTML, html)
    }

    func testFirstNextTokenType1() {
        let cnt1 = "as\n\\View()"
        let lex1: LexicalAnalysis = NutLexical(content: cnt1)

        var _nextTokenType1: NextTokenType? = nil

        XCTAssertNoThrow(_nextTokenType1 = try lex1.nextTokenType())
        XCTAssertNotNil(_nextTokenType1)
        guard let nextTokenType1 = _nextTokenType1 else {
            XCTFail()
            return
        }
        if nextTokenType1 != .html {
            XCTFail()
        }
    }

    func testFirstNextTokenType2() {
        let cnt1 = "\\\\View()"
        let lex1: LexicalAnalysis = NutLexical(content: cnt1)

        var _nextTokenType1: NextTokenType? = nil

        XCTAssertNoThrow(_nextTokenType1 = try lex1.nextTokenType())
        XCTAssertNotNil(_nextTokenType1)
        guard let nextTokenType1 = _nextTokenType1 else {
            XCTFail()
            return
        }
        if nextTokenType1 != .html {
            XCTFail()
        }
    }

    func testFirstNextTokenType3() {
        let cnt1 = "\\View() asd"
        let lex1: LexicalAnalysis = NutLexical(content: cnt1)

        var _nextTokenType1: NextTokenType? = nil

        XCTAssertNoThrow(_nextTokenType1 = try lex1.nextTokenType())
        XCTAssertNotNil(_nextTokenType1)
        guard let nextTokenType1 = _nextTokenType1 else {
            XCTFail()
            return
        }
        if nextTokenType1 != .command {
            XCTFail()
        }
    }


    func testFirstNextTokenType4() {
        let cnt1 = "\\"
        let lex1: LexicalAnalysis = NutLexical(content: cnt1)

        do {
            let _ = try lex1.nextTokenType()
            XCTFail()
        } catch let err {
            guard let err = err as? NutLexical.LexicalError else {
                XCTFail()
                return
            }
            guard case .unexpectedEnd(_) = err else {
                XCTFail()
                return
            }
        }
    }


    static let allTests = [
        ("testSimple", testSimple),
        ("testCommented", testCommented),
        ("testFirstNextTokenType1", testFirstNextTokenType1),
        ("testFirstNextTokenType2", testFirstNextTokenType2),
        ("testFirstNextTokenType3", testFirstNextTokenType3),
        ("testFirstNextTokenType4", testFirstNextTokenType4)
    ]
}
