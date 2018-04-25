//
//  View.swift
//  NutView
//
//  Created by Filip Klembara on 8/4/17.
//
//

import SquirrelJSON

/// Represents html document generated from *.nut.html* file
public struct View {

    private let name: String
    private let data: [String: Any]
    private let interpreter: NutInterpreterProtocol

    /// Construct from name of view
    ///
    /// - Note: For name use dot convention. Instead of "Page/View.nut.html" use "Page.View"
    ///
    /// - Parameter name: Name of View file without extension (*.nut.html*)
    public init(_ name: String) {
        self.name = name
        self.data = [:]
        self.interpreter = NutInterpreter(view: name, with: data)
    }

    /// Construct from name of view
    ///
    /// - Note: For name use dot convention. Instead of "Page/View.nut.html" use "Page.View"
    ///
    /// - Parameter name: Name of View file without extension (*.nut.html*)
    /// - Parameter with: Struct or Class with data which will fill the view
    public init<T>(_ name: String, with object: T) throws {
        self.name = name
        guard let data = JSONCoding.encodeSerializeJSON(object: object) as? [String: Any] else {
            throw JSONError(kind: .encodeError, description: "Encode error")
        }
        self.data = data
        interpreter = NutInterpreter(view: name, with: data)
    }

    /// Constructs from name of view
    ///
    /// - Note:
    ///   This init is deprecated, use init(_:) instead
    ///
    /// - Parameter name: Name of View file without extension (*.nut.html*)
    @available(*, deprecated: 1.0.5, message: "Use init(_:) instead")
    public init(name: String) {
        self.init(name)
    }

    /// Construct from name of view
    ///
    /// - Note: This init is deprecated, use init(_:with:) instead
    ///
    /// - Parameter name: Name of View file without extension (*.nut.html*)
    /// - Parameter with: Struct or Class with data which will fill the view
    @available(*, deprecated: 1.0.5, message: "Use init(_:with:) instead")
    public init<T>(name: String, with object: T?) throws {
        if let obj = object {
            try self.init(name, with: obj)
        } else {
            self.init(name)
        }
    }

    /// Resolve View and return its content
    ///
    /// - Returns: Content of resolved *.nut.html* view and all of ith subviews
    /// - Throws: `NutParserError`
    public func getContent() throws -> String {
        return try interpreter.resolve()
    }
}
