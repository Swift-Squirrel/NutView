//
//  NutParserTests.swift
//  NutViewTests
//
//  Created by Filip Klembara on 9/6/17.
//

import XCTest
@testable import NutView
import SquirrelJSON

extension ViewCommands {
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

class NutParserTests: XCTestCase {

    func testSimpleParse() {
        let parser = NutParser(content: """
            \\Title("Title of post")
            this is about \\(_topic)
            """, name: "Views/Post.nut")

        guard let viewCommands = try? parser.getCommands() else {
            XCTFail()
            return
        }

        XCTAssertEqual(viewCommands.body.count, 3)
        XCTAssert(viewCommands.fileName == "Views/Post.nut")

        let serialized = viewCommands.serialized
        let expected = try! JSON(json: """
            {"body":[{"id":"title","expression":{"expression":"\\"Title of post\\"","id":"escapedValue","line":1},"line":1},{"id":"html","value":"\\nthis is about ","line":2},{"expression":"_topic","id":"escapedValue","line":2}],"fileName":"Views\\/Post.nut"}
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
        XCTAssertNoThrow(try parser.getCommands())
        guard let viewToken = try? parser.getCommands() else {
            XCTFail()
            return
        }

        XCTAssert(viewToken.body.count == 9, String(describing: viewToken.body.count))
        XCTAssert(viewToken.fileName == "Layouts/Default.nut")

        let serialized = viewToken.serialized
        let expected = try! JSON(json: """
            {"body":[{"id":"html","value":"<!-- Default.html -->\\n<!DOCTYPE html>\\n<html lang=\\"en\\">\\n<head>\\n    ","line":1},{"id":"subview","name":{"id":"rawValue","expression":"\\"Page.Head\\"","line":5},"line":5},{"id":"html","value":"\\n<\\/head>\\n<body>\\n    ","line":6},{"id":"subview","name":{"id":"rawValue","expression":"\\"Page.Header.Jumbotron\\"","line":8},"line":8},{"id":"html","value":"\\n<div class=\\"container\\">\\n    <div class=\\"line\\">\\n        <div class=\\"col-8 mx-auto\\">\\n            ","line":9},{"id":"view","line":12},{"id":"html","value":"\\n        <\\/div>\\n    <\\/div>\\n<\\/div>\\n    ","line":13},{"id":"subview","name":{"id":"rawValue","expression":"\\"Page.Footer\\"","line":16},"line":16},{"id":"html","value":"\\n<\\/body>\\n<\\/html>","line":17}],"fileName":"Layouts\\/Default.nut"}
            """)

        XCTAssertEqual(serialized, expected)
    }

    func testUnknownCommand() {
        let content = """
            dmth \\unknown()
            """
        let parser = NutParser(content: content, name: "Subviews/Unknown.nut")
        XCTAssertThrowsError(try parser.getCommands())

        do {
            let _ = try parser.getCommands()
            XCTFail()
        } catch let error as NutParserError {
            guard case let .lexical(lexError) = error.kind else {
                XCTFail(error.description)
                return
            }
            guard case let .unknownCommand(command, line) = lexError else {
                XCTFail(error.description)
                return
            }
            XCTAssertEqual(command, "unknown")
            XCTAssertEqual(line, 1)
        } catch let error {
            XCTFail(String(describing: error))
        }
    }

    func testCommentedCommand() {
        let content = """
            dmth \\\\(smth)
            """
        let parser = NutParser(content: content, name: "Subviews/Unknown.nut")
        guard let viewToken = try? parser.getCommands() else {
            XCTFail()
            return
        }
        XCTAssert(viewToken.body.count == 1)
        let serialized = viewToken.serialized
        XCTAssertEqual(serialized["body"][0]["id"].stringValue, "html")
        XCTAssertEqual(serialized["body"][0]["value"].stringValue, "dmth \\(smth)")
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
            \\}pdso a
            """
        let parser = NutParser(content: content, name: "Subviews/Smt.nut")
        XCTAssertNoThrow(try parser.getCommands())
        guard let viewToken = try? parser.getCommands() else {
            XCTFail()
            return
        }

        XCTAssert(viewToken.body.count == 13, String(describing: viewToken.body.count))
        XCTAssert(viewToken.fileName == "Subviews/Smt.nut")

        let serialized = viewToken.serialized

        let expected = try! JSON(json: """
            {"body":[{"id":"html","value":"dasd alm ak po\\n","line":1},{"id":"date","date":{"id":"rawValue","expression":"date","line":2},"line":2},{"id":"html","value":" oid\\n","line":2},{"id":"if","line":3,"thens":[{"block":[{"id":"html","value":"\\n    asd a ","line":4},{"format":{"id":"rawValue","expression":"\\"m\\" + years","line":4},"id":"date","line":4,"date":{"id":"rawValue","expression":"date1","line":4}},{"id":"html","value":" asda\\n","line":4}],"conditions":[{"condition":{"id":"rawValue","expression":"true ","line":3}}],"line":3}]},{"id":"html","value":"\\n","line":6},{"id":"if","line":6,"thens":[{"block":[{"id":"html","value":"\\n    true\\n","line":7}],"conditions":[{"condition":{"id":"rawValue","expression":"1 + 3 == 4 ","line":6}}],"line":6},{"block":[{"id":"html","value":"\\n    ","line":9},{"id":"escapedValue","expression":"true","line":9},{"id":"html","value":"\\n","line":10}],"conditions":[{"condition":{"id":"rawValue","expression":"true == true ","line":8}}],"line":8},{"block":[{"id":"html","value":"\\n    doefja e\\n","line":11}],"conditions":[{"condition":{"id":"rawValue","expression":"posts ","line":10},"variable":"notNil"}],"line":10}]},{"id":"html","value":"\\n","line":13},{"else":[{"id":"html","value":"\\n    ds\\n    ","line":16},{"id":"subview","name":{"id":"rawValue","expression":"\\"Map\\"","line":17},"line":17},{"id":"html","value":"\\n","line":18}],"thens":[{"block":[{"id":"html","value":"\\n    dfe\\n","line":14}],"conditions":[{"condition":{"id":"rawValue","expression":"Tom ","line":13},"variable":"asd"}],"line":13}],"id":"if","line":13},{"id":"html","value":"\\n\\n","line":20},{"collection":"posts","value":"post","id":"for","commands":[{"id":"html","value":"\\n    ","line":21},{"id":"rawValue","expression":"post.body","line":21},{"id":"html","value":"\\n","line":22}],"line":20},{"id":"html","value":"\\n","line":23},{"collection":"dictionary","value":"value","id":"for","commands":[{"id":"html","value":"\\n    ","line":24},{"id":"escapedValue","expression":"key + \\" \\" + value","line":24},{"id":"html","value":"\\n","line":25}],"key":"key","line":23},{"id":"html","value":"pdso a","line":25}],"fileName":"Subviews\\/Smt.nut"}
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

        guard let viewToken = try? parser.getCommands() else {
            XCTFail()
            return
        }

        XCTAssertEqual(4, viewToken.body.count)
        XCTAssertEqual(viewToken.fileName, "Views/Smt.nut")

        let serialized = viewToken.serialized

        let expected = try! JSON(json: """
            {"body":[{"id":"html","value":"dasd alm ak po\\n","line":1},{"id":"layout","name":{"id":"rawValue","expression":"\\"Default\\"","line":2},"line":2},{"id":"html","value":"\\n","line":3},{"id":"title","expression":{"id":"escapedValue","expression":"\\"ds\\"","line":3},"line":3}],"fileName":"Views\\/Smt.nut"}
            """)

        XCTAssertEqual(serialized, expected)
    }

    func testExpressions() {
        let content = """
            \\(tag)
            \\RawValue(tag)
            """
        let parser = NutParser(content: content, name: "Views/V1.nut")

        guard let viewToken = try? parser.getCommands() else {
            XCTFail()
            return
        }

        XCTAssert(viewToken.body.count == 3, String(describing: viewToken.body.count))
        XCTAssert(viewToken.fileName == "Views/V1.nut")

        let serialized = viewToken.serialized

        let expected = try! JSON(json: """
            {"body":[{"id":"escapedValue","expression":"tag","line":1},{"id":"html","value":"\\n","line":2},{"id":"rawValue","expression":"tag","line":2}],"fileName":"Views\\/V1.nut"}
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

        guard let viewToken = try? parser.getCommands() else {
            XCTFail()
            return
        }

        XCTAssert(viewToken.body.count == 3, String(describing: viewToken.body.count))
        XCTAssert(viewToken.fileName == "Layouts/Smt.nut")

        let serialized = viewToken.serialized

        let expected = try! JSON(json: """
            {"body":[{"id":"html","value":"dasd alm ak po\\n","line":1},{"id":"view","line":2},{"id":"html","value":"\\n    fa","line":3}],"fileName":"Layouts\\/Smt.nut"}
            """)

        XCTAssertEqual(serialized, expected)
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

        guard let viewToken = try? parser.getCommands() else {
            XCTFail()
            return
        }

        XCTAssertEqual(viewToken.body.count, 4)
        XCTAssert(viewToken.fileName == "Views/Smt.nut")

        let serialized = viewToken.serialized

        let expected = try! JSON(json: """
            {"body":[{"id":"layout","name":{"id":"rawValue","expression":"\\"DefaultLayout\\"","line":1},"line":1},{"id":"html","value":"\\n","line":2},{"id":"title","expression":{"id":"escapedValue","expression":"\\"Dates\\"","line":2},"line":2},{"id":"html","value":"\\n\\n<h1>Dates<\\/h1>\\nDate(_:format:)\\n<ul>\\n<li>\\\\Date(_:)<\\/li>\\n<li>\\\\Date(_:format:)<\\/li>\\n<\\/ul>","line":4}],"fileName":"Views\\/Smt.nut"}
            """)

        XCTAssertEqual(serialized, expected)
    }

    func testVarName1() {
        let content = """
        \\if let _a = a {\\(a)\\}
        """
        let parser = NutParser(content: content, name: "Views/Smt.nut")
        XCTAssertNoThrow(try parser.getCommands())
        guard let viewToken = try? parser.getCommands() else {
            XCTFail()
            return
        }

        XCTAssertEqual(viewToken.body.count, 1)
        XCTAssertEqual(viewToken.fileName, "Views/Smt.nut")

        let serialized = viewToken.serialized

        let expected = try! JSON(json: """
            {"body":[{"id":"if","line":1,"thens":[{"block":[{"id":"escapedValue","expression":"a","line":1}],"conditions":[{"condition":{"id":"rawValue","expression":"a ","line":1},"variable":"_a"}],"line":1}]}],"fileName":"Views\\/Smt.nut"}
            """)

        XCTAssertEqual(serialized, expected)

    }

    func testVarName2() {
        let content = """
        \\if let __a = a {\\(a)\\}
        """
        let parser = NutParser(content: content, name: "Views/Smt1.nut")

        var vt: ViewCommands! = nil

        XCTAssertNoThrow(vt = try parser.getCommands())

        guard let viewToken = vt else {
            XCTFail()
            return
        }


        XCTAssertEqual(viewToken.body.count, 1)
        XCTAssertEqual(viewToken.fileName, "Views/Smt1.nut")

        let serialized = viewToken.serialized

        let expected = try! JSON(json: """
            {"body":[{"id":"if","line":1,"thens":[{"block":[{"id":"escapedValue","expression":"a","line":1}],"conditions":[{"condition":{"id":"rawValue","expression":"a ","line":1},"variable":"__a"}],"line":1}]}],"fileName":"Views\\/Smt1.nut"}
            """)

        XCTAssertEqual(serialized, expected)
    }

    func testVarName3() {
        let content = """
        \\if let _a_ = a {\\(a)\\}
        """
        let parser = NutParser(content: content, name: "Views/Smt.nut")

        guard let viewToken = try? parser.getCommands() else {
            XCTFail()
            return
        }

        XCTAssertEqual(viewToken.body.count, 1)
        XCTAssertEqual(viewToken.fileName, "Views/Smt.nut")

        let serialized = viewToken.serialized

        let expected = try! JSON(json: """
            {"body":[{"id":"if","line":1,"thens":[{"block":[{"id":"escapedValue","expression":"a","line":1}],"conditions":[{"condition":{"id":"rawValue","expression":"a ","line":1},"variable":"_a_"}],"line":1}]}],"fileName":"Views\\/Smt.nut"}
            """)

        XCTAssertEqual(serialized, expected)
    }

    func testVarName4() {
        let content = """
        \\if let a_=a{\\(a)\\}
        """
        let parser = NutParser(content: content, name: "Views/Smt.nut")

        guard let viewToken = try? parser.getCommands() else {
            XCTFail()
            return
        }

        XCTAssertEqual(viewToken.body.count, 1)
        XCTAssertEqual(viewToken.fileName, "Views/Smt.nut")

        let serialized = viewToken.serialized

        let expected = try! JSON(json: """
            {"body":[{"id":"if","line":1,"thens":[{"block":[{"id":"escapedValue","expression":"a","line":1}],"conditions":[{"condition":{"id":"rawValue","expression":"a","line":1},"variable":"a_"}],"line":1}]}],"fileName":"Views\\/Smt.nut"}
            """)

        XCTAssertEqual(serialized, expected)
    }

    func testVarName5() {
        let content = """
        \\if let a_a_a = a {\\(a)\\}
        """
        let parser = NutParser(content: content, name: "Views/Smt.nut")

        guard let viewToken = try? parser.getCommands() else {
            XCTFail()
            return
        }

        XCTAssertEqual(viewToken.body.count, 1)
        XCTAssertEqual(viewToken.fileName, "Views/Smt.nut")

        let serialized = viewToken.serialized

        let expected = try! JSON(json: """
            {"body":[{"id":"if","line":1,"thens":[{"block":[{"id":"escapedValue","expression":"a","line":1}],"conditions":[{"condition":{"id":"rawValue","expression":"a ","line":1},"variable":"a_a_a"}],"line":1}]}],"fileName":"Views\\/Smt.nut"}
            """)

        XCTAssertEqual(serialized, expected)
    }

    func testVarName6() {
        let content = """
        \\if let a = _a._b_ {\\(a)\\}
        """
        let parser = NutParser(content: content, name: "Views/Smt.nut")

        guard let viewToken = try? parser.getCommands() else {
            XCTFail()
            return
        }

        XCTAssertEqual(viewToken.body.count, 1)
        XCTAssertEqual(viewToken.fileName, "Views/Smt.nut")

        let serialized = viewToken.serialized

        let expected = try! JSON(json: """
            {"body":[{"id":"if","line":1,"thens":[{"block":[{"id":"escapedValue","expression":"a","line":1}],"conditions":[{"condition":{"id":"rawValue","expression":"_a._b_ ","line":1},"variable":"a"}],"line":1}]}],"fileName":"Views\\/Smt.nut"}
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
