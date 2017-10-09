import XCTest
@testable import NutViewTests

XCTMain([
	testCase(TokenTests.allTests),
    testCase(NutParserTests.allTests),
    testCase(NutParserErrors.allTests),
    testCase(FruitParserTests.allTests)
])
