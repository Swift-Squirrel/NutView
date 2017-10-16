import XCTest
@testable import NutViewTests
@testable import NutViewIntegrationTests

XCTMain([
	testCase(TokenTests.allTests),
    testCase(NutParserTests.allTests),
    testCase(NutParserErrors.allTests),
    testCase(FruitParserTests.allTests),
    testCase(NutResolverTests.allTests),
    testCase(InterpreterTests.allTests),
    testCase(ViewTests.allTests)
])
