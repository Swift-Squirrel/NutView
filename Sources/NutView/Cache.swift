//
//  Cache.swift
//  NutView
//
//  Created by Filip Klembara on 9/10/17.
//

import SquirrelCache
import Foundation

extension ViewCommands: Cachable {
    static func decode(_ data: Data) -> CacheType? {
        let fruitParser: FruitParserProtocol.Type = FruitParser.self
        guard let commands = try? fruitParser.decodeCommands(data: data) else {
            return nil
        }
        return commands
    }

    func encode() -> Data? {
        let fruitParser: FruitParserProtocol.Type = FruitParser.self
        guard let data = try? fruitParser.encodeCommands(self) else {
            return nil
        }
        return data
    }

    typealias CacheType = ViewCommands
}
