//
//  ViewToken.swift
//  NutView
//
//  Created by Filip Klembara on 1/27/18.
//

// swiftlint:disable file_length

import Foundation

struct ViewCommands: Codable {
    let fileName: String
    let body: [Command]

    init(name: String, body: [Command]) {
        self.fileName = name
        self.body = body
    }

    private enum CodingKeys: String, CodingKey {
        case fileName
        case version
        case body
        case head
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fileName, forKey: .fileName)
        var unkeyedContainerBody = container.nestedUnkeyedContainer(forKey: .body)
        try ViewCommands.encode(commands: body, unkeyedContainer: &unkeyedContainerBody)
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fileName = try container.decode(String.self, forKey: .fileName)
        var unkeyedContainer = try container.nestedUnkeyedContainer(forKey: .body)
        body = try ViewCommands.decode(unkeyedContainer: &unkeyedContainer)
    }
}

protocol Command: Codable {
    var id: ViewCommands.CommandType { get }
    var line: Int { get }
}

protocol HeadCommand: Command { }

protocol BodyCommand: Command { }

protocol ExpressionCommand: Command {
    var expression: String { get }
}

extension ExpressionCommand {
    func evaluate(with data: [String: Any]) throws -> Any? {
        return try expression.evaluate(with: data)
    }
}

// MARK: - Commands
extension ViewCommands {
    struct For: Command {
        let id: CommandType = .`for`
        let key: String?
        let value: String
        let collection: String
        let commands: [Command]
        let line: Int
        init(key: String? = nil,
             value: String,
             collection: String,
             commands: [Command] = [],
             line: Int) {

            self.key = key
            self.value = value
            self.collection = collection
            self.commands = commands
            self.line = line
        }
    }

    struct Head: HeadCommand {
        let id: CommandType = .head
        let expression: RawValue
        let line: Int
    }

    struct Title: HeadCommand {
        let id: CommandType = .title
        let expression: EscapedValue
        let line: Int
    }

    struct Body: BodyCommand {
        let id: CommandType = .body
        let expression: RawValue
        let line: Int
    }

    struct EscapedValue: ExpressionCommand {
        let id: CommandType = .escapedValue
        let expression: String
        let line: Int
    }

    struct Subview: Command {
        let id: CommandType = .subview
        let name: RawValue
        let line: Int
        init(name: String, line: Int) {
            let value = RawValue(expression: name, line: line)
            self.init(name: value, line: line)
        }
        init(name: RawValue, line: Int) {
            self.name = name
            self.line = line
        }
    }
    // swiftlint:disable:next type_name
    struct If: Command {
        struct ThenBlock: Codable {
            enum ConditionType {
                case simple(condition: RawValue)
                case cast(variable: String, condition: RawValue)
            }
            let conditions: [ConditionType]
            let block: [Command]
            let line: Int
        }
        let id: CommandType = .`if`
        private(set) var thens: [ThenBlock]
        private(set) var `else`: [Command]
        let line: Int

        init(variable: String? = nil,
             condition: String,
             then: [Command] = [],
             else: [Command] = [],
             line: Int) {

            let rawValue = ViewCommands.RawValue(expression: condition, line: line)
            self.init(variable: variable, condition: rawValue, then: then, else: `else`, line: line)
        }

        init(variable: String? = nil,
             condition: RawValue,
             then: [Command] = [],
             else: [Command] = [],
             line: Int) {

            let conditionType: ThenBlock.ConditionType
            if let variable = variable {
                conditionType = .cast(variable: variable, condition: condition)
            } else {
                conditionType = .simple(condition: condition)
            }
            self.thens = []
            self.`else` = `else`
            self.line = line
            let thenBlock = ThenBlock(conditions: [conditionType], block: then, line: line)
            add(thenBlock: thenBlock)
        }

        init(then: ThenBlock, else: [Command] = [], line: Int) {
            self.thens = []
            self.`else` = `else`
            self.line = line
            add(thenBlock: then)
        }

        init(conditions: [ThenBlock.ConditionType],
             then: [Command],
             else: [Command] = [],
             line: Int) {

            let thenB = ThenBlock(conditions: conditions, block: then, line: line)
            self.init(then: thenB, else: `else`, line: line)
        }

        mutating func add(thenBlock: ThenBlock) {
            if thenBlock.block.isEmpty {
                return
            }
            thens.append(thenBlock)
        }

        mutating func add(conditions: [ThenBlock.ConditionType], then: [Command], line: Int) {
            let thenBlock = ThenBlock(conditions: conditions, block: then, line: line)
            add(thenBlock: thenBlock)
        }

        mutating func setElse(body: [Command]) {
            `else` = body
        }
    }

    struct Date: Command {
        let id: CommandType = .date
        let date: RawValue
        let format: RawValue?
        let line: Int

        init(date: RawValue, format: RawValue? = nil, line: Int) {
            self.date = date
            self.format = format
            self.line = line
        }
    }

    struct RawValue: ExpressionCommand {
        let id: CommandType = .rawValue
        let expression: String
        let line: Int
    }

    struct InsertView: Command {
        let id: CommandType = .view
        let line: Int
    }

    struct HTML: Command {
        let id: CommandType = .html
        let value: String
        let line: Int
    }

    struct Layout: Command {
        let id: CommandType = .layout
        let name: RawValue
        let line: Int
        init(name: String, line: Int) {
            let value = RawValue(expression: name, line: line)
            self.init(name: value, line: line)
        }
        init(name: RawValue, line: Int) {
            self.name = name
            self.line = line
        }
    }
}

extension ViewCommands {
    // swiftlint:disable:next cyclomatic_complexity
    static func encode(commands: [Command],
                       unkeyedContainer container: inout UnkeyedEncodingContainer) throws {

        try commands.forEach { command in
            switch command {
            case let date as ViewCommands.Date:
                try container.encode(date)
            case let ifCmd as If:
                try container.encode(ifCmd)
            case let view as InsertView:
                try container.encode(view)
            case let html as HTML:
                try container.encode(html)
            case let layout as Layout:
                try container.encode(layout)
            case let subview as Subview:
                try container.encode(subview)
            case let title as Title:
                try container.encode(title)
            case let head as Head:
                try container.encode(head)
            case let value as EscapedValue:
                try container.encode(value)
            case let value as RawValue:
                try container.encode(value)
            case let forCmd as For:
                try container.encode(forCmd)
            case let body as Body:
                try container.encode(body)
            default:
                let context = EncodingError.Context(codingPath: [],
                                                    debugDescription: "Unknown command \(command)")
                throw EncodingError.invalidValue(command, context)
            }
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    static func decode(unkeyedContainer container: inout UnkeyedDecodingContainer)
        throws -> [Command] {

            enum NestedCodingKeys: String, CodingKey {
                case id
            }
            var commands = [Command]()
            while !container.isAtEnd {
                var pomContainer = container
                let nested = try pomContainer.nestedContainer(keyedBy: NestedCodingKeys.self)
                let id = try nested.decode(ViewCommands.CommandType.self, forKey: .id)
                let command: Command
                switch id {
                case .html:
                    command = try container.decode(HTML.self)
                case .view:
                    command = try container.decode(InsertView.self)
                case .date:
                    command = try container.decode(Date.self)
                case .rawValue:
                    command = try container.decode(RawValue.self)
                case .escapedValue:
                    command = try container.decode(EscapedValue.self)
                case .`if`:
                    command = try container.decode(If.self)
                case .layout:
                    command = try container.decode(Layout.self)
                case .subview:
                    command = try container.decode(Subview.self)
                case .title:
                    command = try container.decode(Title.self)
                case .head:
                    command = try container.decode(Head.self)
                case .`for`:
                    command = try container.decode(For.self)
                case .body:
                    command = try container.decode(Body.self)
                }
                commands.append(command)
            }
            return commands
    }
}

extension ViewCommands.For {
    private enum CodingKeys: String, CodingKey {
        case id
        case key
        case value
        case collection
        case commands
        case line
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(key, forKey: .key)
        try container.encode(value, forKey: .value)
        try container.encode(collection, forKey: .collection)
        if !commands.isEmpty {
            var unkeydContainer = container.nestedUnkeyedContainer(forKey: .commands)
            try ViewCommands.encode(commands: commands, unkeyedContainer: &unkeydContainer)
        }
        try container.encode(line, forKey: .line)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let oid = try container.decode(ViewCommands.CommandType.self, forKey: .id)
        guard oid == id else {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.id,
                                                   in: container,
                                                   debugDescription: "Wrong ID")
        }
        key = try container.decodeIfPresent(String.self, forKey: .key)
        value = try container.decode(String.self, forKey: .value)
        collection = try container.decode(String.self, forKey: .collection)
        if var unkeyedContainer = try? container.nestedUnkeyedContainer(forKey: .commands) {
            commands = try ViewCommands.decode(unkeyedContainer: &unkeyedContainer)
        } else {
            commands = []
        }
        line = try container.decode(Int.self, forKey: .line)
    }
}

extension ViewCommands.If.ThenBlock.ConditionType: Codable {
    private enum CodingKeys: String, CodingKey {
        case condition
        case variable
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let condition = try container.decode(ViewCommands.RawValue.self, forKey: .condition)
        if let variable = try container.decodeIfPresent(String.self, forKey: .variable) {
            self = .cast(variable: variable, condition: condition)
        } else {
            self = .simple(condition: condition)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .simple(let condition):
            try container.encode(condition, forKey: .condition)
        case .cast(let variable, let condition):
            try container.encode(condition, forKey: .condition)
            try container.encode(variable, forKey: .variable)
        }
    }
}

extension ViewCommands.If.ThenBlock {
    private enum CodingKeys: String, CodingKey {
        case conditions
        case block
        case line
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        conditions = try container.decode([ConditionType].self, forKey: .conditions)
        var unkeyedContainer = try container.nestedUnkeyedContainer(forKey: .block)
        block = try ViewCommands.decode(unkeyedContainer: &unkeyedContainer)
        line = try container.decode(Int.self, forKey: .line)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(conditions, forKey: .conditions)
        var unkeyedContainer = container.nestedUnkeyedContainer(forKey: .block)
        try ViewCommands.encode(commands: block, unkeyedContainer: &unkeyedContainer)
        try container.encode(line, forKey: .line)
    }
}

extension ViewCommands.If {
    private enum CodingKeys: String, CodingKey {
        case id
        case thens
        case `else`
        case line
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(line, forKey: .line)
        if !thens.isEmpty {
            try container.encode(thens, forKey: .thens)
        }
        if !`else`.isEmpty {
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .else)
            try ViewCommands.encode(commands: `else`, unkeyedContainer: &nestedContainer)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let oid = try container.decode(ViewCommands.CommandType.self, forKey: .id)
        guard oid == id else {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.id,
                                                   in: container,
                                                   debugDescription: "Wrong ID")
        }
        line = try container.decode(Int.self, forKey: .line)

        thens = try container.decodeIfPresent([ThenBlock].self, forKey: .thens) ?? []
        if var unkeyedContainer = try? container.nestedUnkeyedContainer(forKey: .`else`) {
            `else` = try ViewCommands.decode(unkeyedContainer: &unkeyedContainer)
        } else {
            `else` = []
        }
    }
}

// MARK: - CommandType
extension ViewCommands {
    enum CommandType: String, Codable {
        case html
        case view
        case date
        case rawValue
        case escapedValue
        case `if`
        case layout
        case subview
        case title
        case head
        case body
        case `for`
    }
}
