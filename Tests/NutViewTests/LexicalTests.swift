//
//  LexicalTests.swift
//  NutViewTests
//
//  Created by Filip Klembara on 1/27/18.
//

import XCTest
@testable import NutView

class LexicalTests: XCTestCase {

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
        ("testCommented", testCommented),
        ("testFirstNextTokenType1", testFirstNextTokenType1),
        ("testFirstNextTokenType2", testFirstNextTokenType2),
        ("testFirstNextTokenType3", testFirstNextTokenType3),
        ("testFirstNextTokenType4", testFirstNextTokenType4)
    ]
}
