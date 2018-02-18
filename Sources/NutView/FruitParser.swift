//
//  FruitParser.swift
//  NutView
//
//  Created by Filip Klembara on 1/27/18.
//

import Foundation

class FruitParser: FruitParserProtocol {
    static func decodeCommands(data: Data) throws -> ViewCommands {
        let decoder = JSONDecoder()
        let cmds = try decoder.decode(ViewCommands.self, from: data)
        return cmds
    }

    static func encodeCommands(_ commands: ViewCommands) throws -> Data {
        let encoder = JSONEncoder()
        let data = try encoder.encode(commands)
        return data
    }
}
