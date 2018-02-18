//
//  TokenTests.swift
//  NutViewTests
//
//  Created by Filip Klembara on 9/5/17.
//

import XCTest
import Foundation
import SquirrelJSON
@testable import NutView

extension Command {
    var serialized: JSON {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self) else {
            assertionFailure()
            return nil
        }
        guard let any = try? JSONSerialization.jsonObject(with: data) else {
            assertionFailure()
            return nil
        }
        guard let dic = any as? [String: Any] else {
            assertionFailure()
            return nil
        }
        guard let json = JSON(dictionary: dic) else {
            assertionFailure()
            return nil
        }
        return json
    }
}

class TokenTests: XCTestCase {
    func testTextToken() {
        let token = ViewCommands.HTML(value: "value", line: 2)

        XCTAssert(token.id.rawValue == "html")
        XCTAssert(token.value == "value")
        XCTAssertEqual(token.line, 2)

        let serialized = token.serialized
        XCTAssert(serialized["id"].string == "html")
        XCTAssert(serialized["value"].string == "value")
        XCTAssertEqual(serialized["line"].int, 2)
    }

    func testInsertView() {
        let token = ViewCommands.InsertView(line: 3)

        XCTAssert(token.id.rawValue == "view")
        XCTAssert(token.line == 3)

        let serialized = token.serialized
        XCTAssert(serialized["id"].string == "view")
        XCTAssert(serialized["line"].int == 3)


        let token1 = ViewCommands.InsertView(line: 2)

        XCTAssert(token1.id.rawValue == "view")
        XCTAssert(token1.line == 2)

        let serialized1 = token1.serialized
        XCTAssert(serialized1["id"].string == "view")
        XCTAssert(serialized1["line"].int == 2)
    }

    func testDate() {
        let token = ViewCommands.Date(
            date: ViewCommands.RawValue(
                expression: "date",
                line: 5),
            format: ViewCommands.RawValue(
                expression: "\"MMM dd YY\"",
                line: 5), line: 5)

        XCTAssert(token.date.expression == "date")
        XCTAssert(token.format?.expression == "\"MMM dd YY\"")
        XCTAssert(token.id.rawValue == "date")
        XCTAssert(token.line == 5)

        let serialized = JSON(from: token.serialized)
        let expected = try! JSON(json: """
            {"id": "date","date": {"id": "rawValue","expression": "date",
            "line": 5},"format": {"id": "rawValue","expression": "\\"MMM dd YY\\"","line": 5},"line": 5}
            """)
        XCTAssertEqual(expected, serialized)

        let token1 = ViewCommands.Date(
            date: ViewCommands.RawValue(expression: "date1", line: 1),
            line: 1)


        XCTAssert(token1.date.expression == "date1")
        XCTAssertNil(token1.format)
        XCTAssert(token1.id.rawValue == "date")
        XCTAssert(token1.line == 1)

        guard let serialized1 = JSON(from: token1.serialized) else {
            XCTFail()
            return
        }
        let expected1 = try! JSON(json: """
            {"id": "date","date": {"id": "rawValue","expression": "date1","line": 1},"line":1}
            """)

        XCTAssert(serialized1["id"] == expected1["id"])
        XCTAssert(serialized1["date"] == expected1["date"])
        XCTAssert(serialized1["date"]["id"] == expected1["date"]["id"])
        XCTAssert(serialized1["date"]["expression"] == expected1["date"]["expression"])
        XCTAssert(serialized1["date"]["line"] == expected1["date"]["line"])
        XCTAssert(serialized1["format"] == expected1["format"])
        XCTAssertEqual(serialized1["line"], expected1["line"])
        XCTAssertEqual(serialized1, expected1)

        let token2 = ViewCommands.Date(
            date: ViewCommands.RawValue(
                expression: "date2",
                line: 2),
            format: ViewCommands.RawValue(
                expression: "\"MMM YY\"",
                line: 2), line: 2)

        XCTAssert(token2.date.expression == "date2")
        XCTAssert(token2.format?.expression == "\"MMM YY\"")
        XCTAssert(token2.id.rawValue == "date")
        XCTAssert(token2.line == 2)

        let serialized2 = JSON(from: token2.serialized)
        let expected2 = try! JSON(json: """
            {"format":{"expression":"\\"MMM YY\\"","id":"rawValue","line":2},"id":"date","line":2,"date":{"expression":"date2","id":"rawValue","line":2}}
            """)
        XCTAssertEqual(serialized2, expected2)

        let token3 = ViewCommands.Date(
            date: ViewCommands.RawValue(expression: "date19", line: 10),
            line: 10)


        XCTAssert(token3.date.expression == "date19")
        XCTAssertNil(token3.format)
        XCTAssert(token3.id.rawValue == "date")
        XCTAssert(token3.line == 10)

        let serialized3 = JSON(from: token3.serialized)
        let expected3 = try! JSON(json: """
            {"id":"date","date":{"expression":"date19","id":"rawValue","line":10},"line":10}
            """)
        XCTAssertEqual(serialized3, expected3)
    }

    func testIf() { // TODO
        /*var token = ViewCommands.If(condition: ViewCommands.RawValue(expression: "b == true", line: 12), then: [], line: 12)
        
        XCTAssert(token.condition.expression == "b == true")
        XCTAssertTrue(token.else.isEmpty)
        XCTAssert(token.id.rawValue == "if")
        XCTAssert(token.variable == nil)
        XCTAssertTrue(token.then.isEmpty)
        XCTAssert(token.line == 12)

        var serialized = JSON(from: token.serialized)
        var expected = try! JSON(json: """
            {"id":"if","condition":{"expression":"b == true","id":"rawValue","line":12},"line":12}
            """)

        XCTAssertEqual(serialized, expected)

        token.setElse(body: [Command]())
        serialized = JSON(from: token.serialized)
        expected = try! JSON(json: """
            {"id":"if","condition":{"expression":"b == true","id":"rawValue","line":12},"line":12}
            """)
        XCTAssertTrue(token.else.isEmpty)
        XCTAssertEqual(serialized, expected)

        // next
        token = ViewCommands.If(variable: "b", condition: "true", line: 11)

        XCTAssert(token.condition.expression == "true")
        XCTAssertTrue(token.else.isEmpty)
        XCTAssert(token.id.rawValue == "if")
        XCTAssert(token.variable == "b")
        XCTAssert(token.then.count == 0)
        XCTAssert(token.line == 11)

        serialized = JSON(from: token.serialized)
        expected = try! JSON(json: """
            {"id":"if","condition":{"expression":"true","id":"rawValue","line":11},"line":11,"variable":"b"}
            """)

        XCTAssertEqual(serialized, expected)

        token.setElse(body: [Command]())
        serialized = JSON(from: token.serialized)
        expected = try! JSON(json: """
            {"id":"if","condition":{"expression":"true","id":"rawValue","line":11},"line":11,"variable":"b"}
            """)
        XCTAssertTrue(token.else.isEmpty)
        XCTAssertEqual(serialized, expected)

        // next
        token = ViewCommands.If(variable: "b", condition: ViewCommands.RawValue(expression: "true", line: 15), line: 15)

        XCTAssert(token.condition.expression == "true")
        XCTAssertTrue(token.`else`.isEmpty)
        XCTAssert(token.id.rawValue == "if")
        XCTAssert(token.variable == "b")
        XCTAssertTrue(token.then.isEmpty)
        XCTAssert(token.line == 15)

        serialized = JSON(from: token.serialized)
        expected = try! JSON(json: """
            {"id":"if","condition":{"expression":"true","id":"rawValue","line":15},"line":15,"variable":"b"}
            """)

        XCTAssertEqual(serialized, expected)

        token.setElse(body: [ViewCommands.HTML(value: "ola", line: 17)])
        serialized = JSON(from: token.serialized)
        expected = try! JSON(json: """
            {"id":"if","condition":{"expression":"true","id":"rawValue","line":15},"line":15,"else":[{"id":"html","value":"ola","line":17}],"variable":"b"}
            """)
        XCTAssertEqual(token.else.count, 1)
        XCTAssertEqual(serialized, expected)*/
    }
//
//    func testElseIf() {
//        guard (try? OldElseIfToken(condition: "a == 21", line: 2)) != nil else {
//            XCTFail()
//            return
//        }
//        var token = try! OldElseIfToken(condition: "a == 21", line: 2)
//
//        XCTAssert(token.getCondition().expression == "a == 21")
//        XCTAssert(token.id == "else if")
//        XCTAssert(token.getElse() == nil)
//        XCTAssert(token.getThen().count == 0)
//        XCTAssert(token.line == 2)
//        XCTAssert(token.variable == nil)
//
//        var serialized = JSON(from: token.serialized)
//        var expected = try! JSON(json: """
//            {"id":"else if","condition":{"expression":"a == 21","id":"rawValue","line":2},"line":2,"then":[]}
//            """)
//        XCTAssertEqual(serialized, expected)
//
//        token.setElse(body: [OldNutTokenProtocol]())
//        XCTAssertNotNil(token.getElse())
//        serialized = JSON(from: token.serialized)
//        expected = try! JSON(json: """
//            {"id":"else if","else":[],"condition":{"expression":"a == 21","id":"rawValue","line":2},"line":2,"then":[]}
//            """)
//        XCTAssertEqual(serialized, expected)
//
//        guard (try? OldElseIfToken(condition: "let b = a", line: 21)) != nil else {
//            XCTFail()
//            return
//        }
//        token = try! OldElseIfToken(condition: "let b = a", line: 21)
//
//        XCTAssert(token.getCondition().expression == "a")
//        XCTAssert(token.id == "else if let")
//        XCTAssert(token.getElse() == nil)
//        XCTAssert(token.getThen().count == 0)
//        XCTAssert(token.line == 21)
//        XCTAssert(token.variable == "b")
//
//        serialized = JSON(from: token.serialized)
//        expected = try! JSON(json: """
//            {"id":"else if let","condition":{"expression":"a","id":"rawValue","line":21},"line":21,"then":[],"variable":"b"}
//            """)
//        XCTAssertEqual(serialized, expected)
//
//        token.setElse(body: [OldNutTokenProtocol]())
//        XCTAssertNotNil(token.getElse())
//        serialized = JSON(from: token.serialized)
//        expected = try! JSON(json: """
//            {"id":"else if let","else":[],"condition":{"expression":"a","id":"rawValue","line":21},"line":21,"then":[],"variable":"b"}
//            """)
//        XCTAssertEqual(serialized, expected)
//    }

    func testLayout() {
        let token = ViewCommands.Layout(name: "\"Page\"", line: 4)

        XCTAssert(token.id.rawValue == "layout")
        XCTAssert(token.name.expression == "\"Page\"")
        XCTAssert(token.line == 4)

        let serialized = JSON(from: token.serialized)
        let expected = try! JSON(json: """
            {"id":"layout","name":{"id":"rawValue","expression":"\\"Page\\"","line":4},"line":4}
            """)
        XCTAssertEqual(serialized, expected)


        let token1 = ViewCommands.Layout(name: "\"Pages\"", line: 2)

        XCTAssert(token1.id.rawValue == "layout")
        XCTAssert(token1.name.expression == "\"Pages\"")
        XCTAssert(token1.line == 2)

        let serialized1 = JSON(from: token1.serialized)
        let expected1 = try! JSON(json: """
            {"id":"layout","name":{"id":"rawValue","expression":"\\"Pages\\"","line":2},"line":2}
            """)
        XCTAssertEqual(serialized1, expected1)
    }

    func testSubview() {
        var token = ViewCommands.Subview(name: "Nav", line: 1)

        XCTAssert(token.id.rawValue == "subview")
        XCTAssert(token.name.expression == "Nav")
        XCTAssert(token.line == 1)
        var serialized = JSON(from: token.serialized)
        var expected = try! JSON(json: """
            {"id":"subview","name":{"id":"rawValue","expression":"Nav","line":1},"line":1}
            """)
        XCTAssertEqual(serialized, expected)

        // next
        token = ViewCommands.Subview(name: "\"Footer\"", line: 42)

        XCTAssert(token.id.rawValue == "subview")
        XCTAssert(token.name.expression == "\"Footer\"")
        XCTAssert(token.line == 42)
        serialized = JSON(from: token.serialized)
        expected = try! JSON(json: """
            {"id":"subview","name":{"id":"rawValue","expression":"\\"Footer\\"","line":42},"line":42}
            """)
        XCTAssertEqual(serialized, expected)
    }

    func testTitle() {
        let token = ViewCommands.Title(expression: ViewCommands.EscapedValue(expression: "title", line: 14), line: 14)

        XCTAssert(token.expression.expression == "title")
        XCTAssertEqual(token.expression.id, .escapedValue)
        XCTAssert(token.id.rawValue == "title")
        XCTAssert(token.line == 14)
        let serialized = JSON(from: token.serialized)
        let expected = try! JSON(json: """
            {"id":"title","expression":{"expression":"title","id":"escapedValue","line":14},"line":14}
            """)
        XCTAssertEqual(serialized, expected)
    }

    func testForIn() {
        var token = ViewCommands.For(key: "k", value: "v", collection: "dic", line: 52)

        XCTAssert(token.collection == "dic")
        XCTAssert(token.commands.count == 0)
        XCTAssert(token.id.rawValue == "for")
        XCTAssert(token.key == "k")
        XCTAssert(token.line == 52)
        XCTAssert(token.value == "v")

        var serialized = JSON(from: token.serialized)
        var expected = try! JSON(json: """
            {"id":"for","key":"k","value":"v","collection":"dic","line":52}
            """)
        XCTAssertEqual(serialized, expected)

        token = ViewCommands.For(value: "val", collection: "arr", line: 214)

        XCTAssert(token.collection == "arr")
        XCTAssert(token.commands.count == 0)
        XCTAssert(token.id.rawValue == "for")
        XCTAssertNil(token.key)
        XCTAssert(token.line == 214)
        XCTAssert(token.value == "val")

        serialized = JSON(from: token.serialized)
        expected = try! JSON(json: """
            {"id":"for","value":"val","collection":"arr","line":214}
            """)
        XCTAssert(serialized == expected)
    }
//
//    func testElse() {
//        let token = OldElseToken(line: 421)
//
//        XCTAssert(token.getBody().count == 0)
//        XCTAssert(token.id == "else")
//        XCTAssert(token.line == 421)
//
//        let serialized = JSON(from: token.serialized)
//        let expected = try! JSON(json: """
//            {"id":"else","line":421}
//            """)
//        XCTAssert(serialized == expected)
//    }
//
//    func testEndBlock() {
//        let token = OldEndBlockToken(line: 1241)
//
//        XCTAssert(token.id == "}")
//        XCTAssert(token.line == 1241)
//        let serialized = JSON(from: token.serialized)
//        let expected = try! JSON(json: """
//            {"id":"}","line":1241}
//            """)
//        XCTAssert(serialized == expected)
//    }
//
    func testExpression() {
        let token = ViewCommands.EscapedValue(expression: "2 * ad", line: 31)

        XCTAssert(token.id.rawValue == "escapedValue")
        XCTAssert(token.expression == "2 * ad")
        XCTAssert(token.line == 31)
        let serialized = JSON(from: token.serialized)
        let expected = try! JSON(json: """
            {"expression":"2 * ad","id":"escapedValue","line":31}
            """)
        XCTAssertEqual(serialized, expected)
    }

    func testRawExpression() {
        let token = ViewCommands.RawValue(expression: "2 * ad", line: 31)

        XCTAssert(token.id.rawValue == "rawValue")
        XCTAssert(token.expression == "2 * ad")
        XCTAssert(token.line == 31)
        let serialized = JSON(from: token.serialized)
        let expected = try! JSON(json: """
            {"expression":"2 * ad","id":"rawValue","line":31}
            """)
        XCTAssertEqual(serialized, expected)
    }

    static let allTests = [
        ("testTextToken", testTextToken),
        ("testInsertView", testInsertView),
        ("testDate", testDate),
        ("testIf", testIf),
//        ("testElseIf", testElseIf),
        ("testLayout", testLayout),
        ("testSubview", testSubview),
        ("testTitle", testTitle),
        ("testForIn", testForIn),
//        ("testElse", testElse),
//        ("testEndBlock", testEndBlock),
        ("testExpression", testExpression),
        ("testRawExpression", testRawExpression)
    ]
}
