//
//  NutParserProtocol.swift
//  NutView
//
//  Created by Filip Klembara on 8/6/17.
//
//

import Foundation

protocol NutParserProtocol {

    init(content: String, name: String)

    func getCommands() throws -> ViewCommands
}

protocol FruitParserProtocol {
    static func decodeCommands(data: Data) throws -> ViewCommands

    static func encodeCommands(_ commands: ViewCommands) throws -> Data
}
