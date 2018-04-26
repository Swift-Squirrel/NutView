//
//  View.swift
//  NutView
//
//  Created by Filip Klembara on 8/4/17.
//
//

import SquirrelJSON

/// Represents html document generated from *.nut.html* file
public class View {

    private let name: String
    private let data: [String: Any]
    private let interpreter: NutInterpreterProtocol

    /// Construct from name of view
    ///
    /// - Note: For name use dot convention. Instead of "Page/View.nut.html" use "Page.View"
    ///
    /// - Parameter name: Name of View file without extension (*.nut.html*)
    public convenience init(_ name: String) {
        self.init(name, with: [:])
    }

    /// Construct from name of view
    ///
    /// - Note: For name use dot convention. Instead of "Page/View.nut.html" use "Page.View"
    ///
    /// - Parameter name: Name of View file without extension (*.nut.html*)
    /// - Parameter with: Struct or Class with data which will fill the view
    public convenience init<T>(_ name: String, with object: T) throws {
        guard let data = JSONCoding.encodeSerializeJSON(object: object) as? [String: Any] else {
            throw JSONError(kind: .encodeError, description: "Encode error")
        }
        self.init(name, with: data)
    }

    private init(_ name: String, with data: [String: Any]) {
        self.name = name
        var resData = data
        resData["view"] = self.name
        self.data = resData
        self.interpreter = NutInterpreter(view: name, with: self.data)
    }

    /// Constructs from name of view
    ///
    /// - Note:
    ///   This init is deprecated, use init(_:) instead
    ///
    /// - Parameter name: Name of View file without extension (*.nut.html*)
    @available(*, deprecated: 1.0.5, message: "Use init(_:) instead")
    public convenience init(name: String) {
        self.init(name)
    }

    /// Construct from name of view
    ///
    /// - Note: This init is deprecated, use init(_:with:) instead
    ///
    /// - Parameter name: Name of View file without extension (*.nut.html*)
    /// - Parameter with: Struct or Class with data which will fill the view
    @available(*, deprecated: 1.0.5, message: "Use init(_:with:) instead")
    public convenience init<T>(name: String, with object: T?) throws {
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
