//
//  NutResolver.swift
//  NutView
//
//  Created by Filip Klembara on 8/11/17.
//
//

import Foundation
import PathKit
import SquirrelCache

protocol NutResolverProtocol {
    static func viewCommands(for name: String) throws -> ViewCommands
}

struct NutResolver: NutResolverProtocol {
    private static var cache: SpecializedCache<ViewCommands> {
        return NutConfig.NutViewCache.cache
    }
    static private let nutExtension = ".nut.html"
    static private let fruitExtension = ".fruit"

    static func viewCommands(for name: String) throws -> ViewCommands {

        let nutName = name.replacingOccurrences(of: ".", with: "/") + nutExtension
        let fruitName = name + fruitExtension
        let fruitParser: FruitParserProtocol.Type = FruitParser.self

        let fruit = NutConfig.fruits + fruitName
        let nut = NutConfig.nuts + nutName

        guard nut.exists else {
            try? cache.removeObject(forKey: name)
            throw NutError(kind: .notExists(name: nutName))
        }

        let fruitValid = isValid(fruit: fruit, nut: nut)
        if let token = cache[name], fruitValid {
            return token
        }

        let vCommands: ViewCommands
        if fruit.exists && fruitValid {
            let content = try fruit.read()
            vCommands = try fruitParser.decodeCommands(data: content)
        } else {
            let content: String = try nut.read()
            let parser = NutParser(content: content, name: nutName)
            vCommands = try parser.getCommands()

            if let fruitContent = try? fruitParser.encodeCommands(vCommands) {
                if fruit.exists {
                    if let cnt = try? fruit.read() {
                        guard cnt != fruitContent else {
                            return vCommands
                        }
                    }
                }
                try? fruit.write(fruitContent)
            }
        }
        try? cache.addObject(vCommands, forKey: name)
        return vCommands
    }

    private static func isValid(fruit: Path, nut: Path) -> Bool {
        guard let fruitModif = getModificationDate(for: fruit) else {
            return false
        }

        guard let nutModif = getModificationDate(for: nut) else {
            return false
        }

        return fruitModif > nutModif
    }

    private static func getModificationDate(for path: Path) -> Date? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path.string) else {
            return nil
        }
        return attributes[FileAttributeKey.modificationDate] as? Date
    }
}
