//
//  View+SquirrelPresentable.swift
//  NutView
//
//  Created by Filip Klembara on 10/16/17.
//

import SquirrelCore
import Foundation

// MARK: - SquirrelPresentable
extension View: SquirrelPresentable {

    /// Representation type
    public var representAs: Representation {
        return .html
    }


    /// View representation in data
    ///
    /// - Returns: View representation in data
    /// - Throws: `NutError`, `EvaluationError` or `DataError`
    public func present() throws -> Data {
        let content = try getContent()
        guard let data = content.data(using: .utf8) else {
            throw DataError(kind: .dataDecodingError(string: content))
        }
        return data
    }
}
