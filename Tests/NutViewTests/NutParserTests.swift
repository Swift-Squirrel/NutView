//
//  NutParserTests.swift
//  NutViewTests
//
//  Created by Filip Klembara on 9/6/17.
//

import XCTest
@testable import NutView
import SquirrelJSON

class NutParserTests: XCTestCase {

    func testSimpleParse() {
        let parser = NutParser(content: """
            \\Title("Title of post")
            this is about \\(_topic)
            """, name: "Views/Post.nut")

        XCTAssert(parser.jsonSerialized == "")

        guard let viewToken = try? parser.tokenize() else {
            XCTFail()
            return
        }

        XCTAssert(viewToken.body.count == 2, String(describing: viewToken.body))
        XCTAssert(viewToken.head.count == 1)
        XCTAssertNil(viewToken.layout)
        XCTAssert(viewToken.name == "Views/Post.nut")

        guard let serialized = try? JSON(json: parser.jsonSerialized) else {
            XCTFail(parser.jsonSerialized)
            return
        }
        let expected = try! JSON(json: """
            {"head":[{"id":"title","expression":{"infix":"\\"Title of post\\"","id":"expression","line":1},"line":1}],"body":[{"id":"text","value":"\\nthis is about "},{"infix":"_topic","id":"expression","line":2}],"fileName":"Views\\/Post.nut"}
            """)

        XCTAssertEqual(serialized, expected)
    }

    func testMediumParse() {
        let content = """
            <!-- Default.html -->
            <!DOCTYPE html>
            <html lang="en">
            <head>
                \\Subview("Page.Head")
            </head>
            <body>
                \\Subview("Page.Header.Jumbotron")
            <div class="container">
                <div class="line">
                    <div class="col-8 mx-auto">
                        \\View()
                    </div>
                </div>
            </div>
                \\Subview("Page.Footer")
            </body>
            </html>
            """
        let parser = NutParser(content: content, name: "Layouts/Default.nut")

        XCTAssert(parser.jsonSerialized == "")

        guard let viewToken = try? parser.tokenize() else {
            XCTFail()
            return
        }

        XCTAssert(viewToken.body.count == 9, String(describing: viewToken.body.count))
        XCTAssert(viewToken.head.count == 0)
        XCTAssertNil(viewToken.layout)
        XCTAssert(viewToken.name == "Layouts/Default.nut")

        guard let serialized = try? JSON(json: parser.jsonSerialized) else {
            XCTFail()
            return
        }
        let expected = try! JSON(json: """
            {"body":[{"id":"text","value":"<!-- Default.html -->\\n<!DOCTYPE html>\\n<html lang=\\"en\\">\\n<head>\\n    "},{"id":"subview","name":"Subviews.Page.Head","line":5},{"id":"text","value":"\\n<\\/head>\\n<body>\\n    "},{"id":"subview","name":"Subviews.Page.Header.Jumbotron","line":8},{"id":"text","value":"\\n<div class=\\"container\\">\\n    <div class=\\"line\\">\\n        <div class=\\"col-8 mx-auto\\">\\n            "},{"id":"view","line":12},{"id":"text","value":"\\n        <\\/div>\\n    <\\/div>\\n<\\/div>\\n    "},{"id":"subview","name":"Subviews.Page.Footer","line":16},{"id":"text","value":"\\n<\\/body>\\n<\\/html>"}],"fileName":"Layouts\\/Default.nut"}
            """)

        XCTAssert(serialized == expected, parser.jsonSerialized)
    }

    func testUnknownCommand() {
        let content = """
            dmth \\unknwon()
            """
        let parser = NutParser(content: content, name: "Subviews/Unknown.nut")
        guard let viewToken = try? parser.tokenize() else {
            XCTFail()
            return
        }
        XCTAssert(viewToken.body.count == 1)
        guard let serialized = try? JSON(json: parser.jsonSerialized) else {
            XCTFail()
            return
        }
        XCTAssert(serialized["body"][0]["id"].stringValue == "text")
        XCTAssert(serialized["body"][0]["value"].stringValue == "dmth \\unknwon()", "expecting 'dmth \\unknwon()' but got '\(serialized["body"][0]["value"].stringValue)'")

    }

    func testCommentedCommand() {
        let content = """
            dmth \\\\(smth)
            """
        let parser = NutParser(content: content, name: "Subviews/Unknown.nut")
        guard let viewToken = try? parser.tokenize() else {
            XCTFail()
            return
        }
        XCTAssert(viewToken.body.count == 1)
        guard let serialized = try? JSON(json: parser.jsonSerialized) else {
            XCTFail()
            return
        }
        XCTAssert(serialized["body"][0]["id"].stringValue == "text")
        XCTAssert(serialized["body"][0]["value"].stringValue == "dmth \\(smth)")
    }

    func testCommonCommands() {
        let content = """
            dasd alm ak po
            \\Date(date) oid
            \\if true {
                asd a \\Date(date1, format: "m" + years) asda
            \\}
            \\if 1 + 3 == 4 {
                true
            \\} else if true == true {
                \\(true)
            \\} else if let notNil = posts {
                doefja e
            \\}
            \\if let asd = Tom {
                dfe
            \\} else {
                ds
                \\Subview("Map")
            \\}

            \\for post in posts {
                \\RawValue(post.body)
            \\}
            \\for (key, value) in dictionary {
                \\(key + " " + value)
            \\}
            pdso a
            """
        let parser = NutParser(content: content, name: "Subviews/Smt.nut")

        XCTAssert(parser.jsonSerialized == "")

        guard let viewToken = try? parser.tokenize() else {
            XCTFail()
            return
        }

        XCTAssert(viewToken.body.count == 13, String(describing: viewToken.body.count))
        XCTAssert(viewToken.head.count == 0)
        XCTAssertNil(viewToken.layout)
        XCTAssert(viewToken.name == "Subviews/Smt.nut")

        guard let serialized = try? JSON(json: parser.jsonSerialized) else {
            XCTFail()
            return
        }

        let expected = try! JSON(json: """
            {"body":[{"id":"text","value":"dasd alm ak po\\n"},{"id":"date","date":{"infix":"date","id":"raw expression","line":2},"line":2},{"id":"text","value":" oid\\n"},{"id":"if","condition":{"infix":"true","id":"raw expression","line":3},"line":3,"then":[{"id":"text","value":"\\n    asd a "},{"format":{"infix":"\\"m\\" + years","id":"raw expression","line":4},"id":"date","line":4,"date":{"infix":"date1","id":"raw expression","line":4}},{"id":"text","value":" asda\\n"}]},{"id":"text","value":"\\n"},{"id":"if","else":[{"id":"if","else":[{"id":"if let","condition":{"infix":"posts","id":"raw expression","line":10},"line":10,"then":[{"id":"text","value":"\\n    doefja e\\n"}],"variable":"notNil"}],"condition":{"infix":"true == true","id":"raw expression","line":8},"line":8,"then":[{"id":"text","value":"\\n    "},{"infix":"true","id":"expression","line":9},{"id":"text","value":"\\n"}]}],"condition":{"infix":"1 + 3 == 4","id":"raw expression","line":6},"line":6,"then":[{"id":"text","value":"\\n    true\\n"}]},{"id":"text","value":"\\n"},{"id":"if let","else":[{"id":"text","value":"    ds\\n    "},{"id":"subview","name":"Subviews.Map","line":17},{"id":"text","value":"\\n"}],"condition":{"infix":"Tom","id":"raw expression","line":13},"line":13,"then":[{"id":"text","value":"\\n    dfe\\n"}],"variable":"asd"},{"id":"text","value":"\\n\\n"},{"array":"posts","id":"for in Array","body":[{"id":"text","value":"\\n    "},{"infix":"post.body","id":"raw expression","line":21},{"id":"text","value":"\\n"}],"line":20,"variable":"post"},{"id":"text","value":"\\n"},{"body":[{"id":"text","value":"\\n    "},{"infix":"key + \\" \\" + value","id":"expression","line":24},{"id":"text","value":"\\n"}],"id":"for in Dictionary","line":23,"array":"dictionary","key":"key","variable":"value"},{"id":"text","value":"\\npdso a"}],"fileName":"Subviews\\/Smt.nut"}
            """)

        XCTAssertEqual(serialized, expected)
    }

    func testViewCommands() {
        let content = """
            dasd alm ak po
            \\Layout("Default")
            \\Title("ds")
            """
        let parser = NutParser(content: content, name: "Views/Smt.nut")

        XCTAssert(parser.jsonSerialized == "")

        guard let viewToken = try? parser.tokenize() else {
            XCTFail()
            return
        }

        XCTAssert(viewToken.body.count == 2, String(describing: viewToken.body.count))
        XCTAssert(viewToken.head.count == 1)
        XCTAssertNotNil(viewToken.layout)
        XCTAssert(viewToken.name == "Views/Smt.nut")

        guard let serialized = try? JSON(json: parser.jsonSerialized) else {
            XCTFail()
            return
        }
        let expected = try! JSON(json: """
            {"body":[{"id":"text","value":"dasd alm ak po\\n"},{"id":"text","value":"\\n"}],"fileName":"Views\\/Smt.nut","head":[{"id":"title","expression":{"infix":"\\"ds\\"","id":"expression","line":3},"line":3}],"layout":{"id":"layout","name":"Layouts.Default","line":2}}
            """)

        XCTAssertEqual(serialized, expected)
    }

    func testExpressions() {
        let content = """
            \\(tag)
            \\RawValue(tag)
            """
        let parser = NutParser(content: content, name: "Views/V1.nut")

        XCTAssert(parser.jsonSerialized == "")

        guard let viewToken = try? parser.tokenize() else {
            XCTFail()
            return
        }

        XCTAssert(viewToken.body.count == 3, String(describing: viewToken.body.count))
        XCTAssert(viewToken.head.count == 0)
        XCTAssertNil(viewToken.layout)
        XCTAssert(viewToken.name == "Views/V1.nut")

        guard let serialized = try? JSON(json: parser.jsonSerialized) else {
            XCTFail()
            return
        }
        let expected = try! JSON(json: """
            {"body":[{"id":"expression","infix":"tag","line":1},{"id":"text","value":"\\n"},{"id":"raw expression","infix":"tag","line":2}],"fileName":"Views\\/V1.nut"}
            """)

        XCTAssertEqual(serialized, expected)

    }

    func testLayoutCommands() {
        let content = """
            dasd alm ak po
            \\View()
                fa
            """
        let parser = NutParser(content: content, name: "Layouts/Smt.nut")

        XCTAssert(parser.jsonSerialized == "")

        guard let viewToken = try? parser.tokenize() else {
            XCTFail()
            return
        }

        XCTAssert(viewToken.body.count == 3, String(describing: viewToken.body.count))
        XCTAssert(viewToken.head.count == 0)
        XCTAssertNil(viewToken.layout)
        XCTAssert(viewToken.name == "Layouts/Smt.nut")

        guard let serialized = try? JSON(json: parser.jsonSerialized) else {
            XCTFail()
            return
        }
        let expected = try! JSON(json: """
            {"body":[{"id":"text","value":"dasd alm ak po\\n"},{"id":"view","line":2},{"id":"text","value":"\\n    fa"}],"fileName":"Layouts\\/Smt.nut"}
            """)

        XCTAssert(serialized == expected, parser.jsonSerialized)
    }

    func testEscapeCommands() {
        let content = """
        \\Layout("DefaultLayout")
        \\Title("Dates")

        <h1>Dates</h1>
        Date(_:format:)
        <ul>
        <li>\\\\Date(_:)</li>
        <li>\\\\Date(_:format:)</li>
        </ul>
        """
        let parser = NutParser(content: content, name: "Views/Smt.nut")

        XCTAssert(parser.jsonSerialized == "")

        guard let viewToken = try? parser.tokenize() else {
            XCTFail()
            return
        }

        XCTAssert(viewToken.body.count == 2, String(describing: viewToken.body.count))
        XCTAssert(viewToken.head.count == 1)
        XCTAssertNotNil(viewToken.layout)
        XCTAssert(viewToken.name == "Views/Smt.nut")

        guard let serialized = try? JSON(json: parser.jsonSerialized) else {
            XCTFail()
            return
        }
        let expected = try! JSON(json: """
            {"layout":{"id":"layout","name":"Layouts.DefaultLayout","line":1},"body":[{"id":"text","value":"\\n"},{"id":"text","value":"\\n\\n<h1>Dates<\\/h1>\\nDate(_:format:)\\n<ul>\\n<li>\\\\Date(_:)<\\/li>\\n<li>\\\\Date(_:format:)<\\/li>\\n<\\/ul>"}],"fileName":"Views\\/Smt.nut","head":[{"id":"title","expression":{"id":"expression","infix":"\\\"Dates\\\"","line":2},"line":2}]}
            """)

        XCTAssert(serialized == expected, parser.jsonSerialized)
    }

    func testVarName1() {
        let content = """
        \\if let _a = a {\\}
        """
        let parser = NutParser(content: content, name: "Views/Smt.nut")

        XCTAssert(parser.jsonSerialized == "")

        guard let viewToken = try? parser.tokenize() else {
            XCTFail()
            return
        }

        XCTAssert(viewToken.body.count == 2, String(describing: viewToken.body.count))
        XCTAssertEqual(viewToken.head.count, 0)
        XCTAssertNil(viewToken.layout)
        XCTAssert(viewToken.name == "Views/Smt.nut")

        guard let serialized = try? JSON(json: parser.jsonSerialized) else {
            XCTFail()
            return
        }
        let expected = try! JSON(json: """
            {"body":[{"variable":"_a","id":"if let","condition":{"id":"raw expression","infix":"a","line":1},"then":[],"line":1},{"id":"text","value":""}],"fileName":"Views\\/Smt.nut"}
            """)

        XCTAssertEqual(serialized, expected)

    }

    func testVarName2() {
        let content = """
        \\if let __a = a {\\}
        """
        let parser = NutParser(content: content, name: "Views/Smt.nut")

        XCTAssert(parser.jsonSerialized == "")

        var vt: ViewToken! = nil

        XCTAssertNoThrow(vt = try parser.tokenize())

        guard let viewToken = vt else {
            XCTFail()
            return
        }


        XCTAssert(viewToken.body.count == 2, String(describing: viewToken.body.count))
        XCTAssertEqual(viewToken.head.count, 0)
        XCTAssertNil(viewToken.layout)
        XCTAssert(viewToken.name == "Views/Smt.nut")

        guard let serialized = try? JSON(json: parser.jsonSerialized) else {
            XCTFail()
            return
        }
        let expected = try! JSON(json: """
            {"body":[{"variable":"__a","id":"if let","condition":{"id":"raw expression","infix":"a","line":1},"then":[],"line":1},{"id":"text","value":""}],"fileName":"Views\\/Smt.nut"}
            """)

        XCTAssertEqual(serialized, expected)
    }

    func testVarName3() {
        let content = """
        \\if let _a_ = a {\\}
        """
        let parser = NutParser(content: content, name: "Views/Smt.nut")

        XCTAssert(parser.jsonSerialized == "")

        guard let viewToken = try? parser.tokenize() else {
            XCTFail()
            return
        }

        XCTAssert(viewToken.body.count == 2, String(describing: viewToken.body.count))
        XCTAssertEqual(viewToken.head.count, 0)
        XCTAssertNil(viewToken.layout)
        XCTAssert(viewToken.name == "Views/Smt.nut")

        guard let serialized = try? JSON(json: parser.jsonSerialized) else {
            XCTFail()
            return
        }
        let expected = try! JSON(json: """
            {"body":[{"variable":"_a_","id":"if let","condition":{"id":"raw expression","infix":"a","line":1},"then":[],"line":1},{"id":"text","value":""}],"fileName":"Views\\/Smt.nut"}
            """)

        XCTAssertEqual(serialized, expected)
    }

    func testVarName4() {
        let content = """
        \\if let a_ = a {\\}
        """
        let parser = NutParser(content: content, name: "Views/Smt.nut")

        XCTAssert(parser.jsonSerialized == "")

        guard let viewToken = try? parser.tokenize() else {
            XCTFail()
            return
        }

        XCTAssert(viewToken.body.count == 2, String(describing: viewToken.body.count))
        XCTAssertEqual(viewToken.head.count, 0)
        XCTAssertNil(viewToken.layout)
        XCTAssert(viewToken.name == "Views/Smt.nut")

        guard let serialized = try? JSON(json: parser.jsonSerialized) else {
            XCTFail()
            return
        }
        let expected = try! JSON(json: """
            {"body":[{"variable":"a_","id":"if let","condition":{"id":"raw expression","infix":"a","line":1},"then":[],"line":1},{"id":"text","value":""}],"fileName":"Views\\/Smt.nut"}
            """)

        XCTAssertEqual(serialized, expected)
    }

    func testVarName5() {
        let content = """
        \\if let a_a_a = a {\\}
        """
        let parser = NutParser(content: content, name: "Views/Smt.nut")

        XCTAssert(parser.jsonSerialized == "")

        guard let viewToken = try? parser.tokenize() else {
            XCTFail()
            return
        }

        XCTAssert(viewToken.body.count == 2, String(describing: viewToken.body.count))
        XCTAssertEqual(viewToken.head.count, 0)
        XCTAssertNil(viewToken.layout)
        XCTAssert(viewToken.name == "Views/Smt.nut")

        guard let serialized = try? JSON(json: parser.jsonSerialized) else {
            XCTFail()
            return
        }
        let expected = try! JSON(json: """
            {"body":[{"variable":"a_a_a","id":"if let","condition":{"id":"raw expression","infix":"a","line":1},"then":[],"line":1},{"id":"text","value":""}],"fileName":"Views\\/Smt.nut"}
            """)

        XCTAssertEqual(serialized, expected)
    }

    func testVarName6() {
        let content = """
        \\if let a = _a._b_ {\\}
        """
        let parser = NutParser(content: content, name: "Views/Smt.nut")

        XCTAssert(parser.jsonSerialized == "")

        guard let viewToken = try? parser.tokenize() else {
            XCTFail()
            return
        }

        XCTAssert(viewToken.body.count == 2, String(describing: viewToken.body.count))
        XCTAssertEqual(viewToken.head.count, 0)
        XCTAssertNil(viewToken.layout)
        XCTAssert(viewToken.name == "Views/Smt.nut")

        guard let serialized = try? JSON(json: parser.jsonSerialized) else {
            XCTFail()
            return
        }
        let expected = try! JSON(json: """
            {"body":[{"variable":"a","id":"if let","condition":{"id":"raw expression","infix":"_a._b_","line":1},"then":[],"line":1},{"id":"text","value":""}],"fileName":"Views\\/Smt.nut"}
            """)

        XCTAssertEqual(serialized, expected)
    }

    static let allTests = [
        ("testSimpleParse", testSimpleParse),
        ("testMediumParse", testMediumParse),
        ("testUnknownCommand", testUnknownCommand),
        ("testCommentedCommand", testCommentedCommand),
        ("testCommonCommands", testCommonCommands),
        ("testViewCommands", testViewCommands),
        ("testExpressions", testExpressions),
        ("testLayoutCommands", testLayoutCommands),
        ("testEscapeCommands", testEscapeCommands),
        ("testVarName1", testVarName1),
        ("testVarName2", testVarName2),
        ("testVarName3", testVarName3),
        ("testVarName4", testVarName4),
        ("testVarName5", testVarName5),
        ("testVarName6", testVarName6),
    ]

}
