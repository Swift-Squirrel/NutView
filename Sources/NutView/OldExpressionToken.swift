//
//  OldExpressionToken.swift
//  NutView
//
//  Created by Filip Klembara on 8/9/17.
//
//

import Evaluation
import SquirrelJSON
import Foundation

@available(*, deprecated, message: "Use without old")
protocol OldExpressionTokenProtocol: OldNutCommandTokenProtocol {
    var infix: String { get }
}

extension OldExpressionTokenProtocol {
    func evaluate(with data: [String: Any]) throws -> Any? {
        return try infix.evaluate(with: data)
    }
}

@available(*, deprecated, message: "Use without old")
struct OldExpressionToken: OldExpressionTokenProtocol {
    let id = "expression"

    let line: Int

    let infix: String

    init(infix: String, line: Int) {
        self.line = line
        self.infix = infix
    }

    var serialized: [String: Any] {
        return ["id": id, "infix": infix, "line": line]
    }
}

@available(*, deprecated, message: "Use without old")
struct OldRawExpressionToken: OldExpressionTokenProtocol {
    let id = "raw expression"

    let line: Int

    let infix: String

    init(infix: String, line: Int) {
        self.infix = infix
        self.line = line
    }

    var serialized: [String: Any] {
        return ["id": id, "infix": infix, "line": line]
    }
}
