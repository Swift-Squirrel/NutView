//
//  FruitParserTests.swift
//  SquirrelTests
//
//  Created by Filip Klembara on 9/6/17.
//

import XCTest
import SquirrelJSON
@testable import NutView

class FruitParserTests: XCTestCase {

    func testSimpleLayout() {
        let content = """
            {"body":[{"id":"html","value":"<!-- Default.html -->\\n<!DOCTYPE html>\\n<html lang=\\"en\\">\\n<head>\\n    ","line":1},{"id":"subview","name":{"id":"rawValue","expression":"\\"Page.Head\\"","line":5},"line":5},{"id":"html","value":"\\n<\\/head>\\n<body>\\n    ","line":6},{"id":"subview","name":{"id":"rawValue","expression":"\\"Page.Header.Jumbotron\\"","line":8},"line":8},{"id":"html","value":"\\n<div class=\\"container\\">\\n    <div class=\\"line\\">\\n        <div class=\\"col-8 mx-auto\\">\\n            ","line":9},{"id":"view","line":12},{"id":"html","value":"\\n        <\\/div>\\n    <\\/div>\\n<\\/div>\\n    ","line":13},{"id":"subview","name":{"id":"rawValue","expression":"\\"Page.Footer\\"","line":16},"line":16},{"id":"html","value":"\\n<\\/body>\\n<\\/html>","line":17}],"fileName":"Layouts\\/Default.nut"}
            """.data(using: .utf8)!
        let parser: FruitParserProtocol.Type = FruitParser.self
        XCTAssertNoThrow(try parser.decodeCommands(data: content))
        guard let viewToken = try? parser.decodeCommands(data: content) else {
            XCTFail()
            return
        }
        XCTAssertEqual(viewToken.body.count, 9)
        XCTAssertEqual(viewToken.fileName, "Layouts/Default.nut")
        let jsonExp = try! JSON(json: content)

        XCTAssertEqual(jsonExp, viewToken.serialized)
    }

    func testSimpleView() {
        let content = """
            {"body":[{"id":"html","value":"dasd alm ak po\\n","line":1},{"id":"date","date":{"id":"rawValue","expression":"date","line":2},"line":2},{"id":"html","value":" oid\\n","line":2},{"id":"if","line":3,"thens":[{"block":[{"id":"html","value":"\\n    asd a ","line":4},{"format":{"id":"rawValue","expression":"\\"m\\" + years","line":4},"id":"date","line":4,"date":{"id":"rawValue","expression":"date1","line":4}},{"id":"html","value":" asda\\n","line":4}],"conditions":[{"condition":{"id":"rawValue","expression":"true ","line":3}}],"line":3}]},{"id":"html","value":"\\n","line":6},{"id":"if","line":6,"thens":[{"block":[{"id":"html","value":"\\n    true\\n","line":7}],"conditions":[{"condition":{"id":"rawValue","expression":"1 + 3 == 4 ","line":6}}],"line":6},{"block":[{"id":"html","value":"\\n    ","line":9},{"id":"escapedValue","expression":"true","line":9},{"id":"html","value":"\\n","line":10}],"conditions":[{"condition":{"id":"rawValue","expression":"true == true ","line":8}}],"line":8},{"block":[{"id":"html","value":"\\n    doefja e\\n","line":11}],"conditions":[{"condition":{"id":"rawValue","expression":"posts ","line":10},"variable":"notNil"}],"line":10}]},{"id":"html","value":"\\n","line":13},{"else":[{"id":"html","value":"\\n    ds\\n    ","line":16},{"id":"subview","name":{"id":"rawValue","expression":"\\"Map\\"","line":17},"line":17},{"id":"html","value":"\\n","line":18}],"thens":[{"block":[{"id":"html","value":"\\n    dfe\\n","line":14}],"conditions":[{"condition":{"id":"rawValue","expression":"Tom ","line":13},"variable":"asd"}],"line":13}],"id":"if","line":13},{"id":"html","value":"\\n\\n","line":20},{"collection":"posts","value":"post","id":"for","commands":[{"id":"html","value":"\\n    ","line":21},{"id":"rawValue","expression":"post.body","line":21},{"id":"html","value":"\\n","line":22}],"line":20},{"id":"html","value":"\\n","line":23},{"collection":"dictionary","value":"value","id":"for","commands":[{"id":"html","value":"\\n    ","line":24},{"id":"escapedValue","expression":"key + \\" \\" + value","line":24},{"id":"html","value":"\\n","line":25}],"key":"key","line":23},{"id":"html","value":"\\npdso a","line":26}],"fileName":"Subviews\\/Smt.nut"}
            """.data(using: .utf8)!

        let parser: FruitParserProtocol.Type = FruitParser.self
        XCTAssertNoThrow(try parser.decodeCommands(data: content))
        guard let viewToken = try? parser.decodeCommands(data: content) else {
            XCTFail()
            return
        }
        XCTAssertEqual(viewToken.body.count, 13)
        XCTAssertEqual(viewToken.fileName, "Subviews/Smt.nut")
        let jsonExp = try! JSON(json: content)
        XCTAssertEqual(jsonExp, viewToken.serialized)
    }
    
    static let allTests = [
        ("testSimpleLayout", testSimpleLayout),
        ("testSimpleView", testSimpleView)
    ]

}
