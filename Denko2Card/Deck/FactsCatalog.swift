import Foundation

/// facts.json 1レコード。指定数量・引火点等の正解値を出典付きで集約したもの（spec-v1.0.md §デッキ 数値突合テスト）。
public struct FactRecord: Codable, Sendable, Equatable {
    public let id: String
    public let value: Double
    public let unit: String
    public let source: String

    public init(id: String, value: Double, unit: String, source: String) {
        self.id = id
        self.value = value
        self.unit = unit
        self.source = source
    }

    /// カードのanswer文字列内に含まれるべき表記（例: "-40℃" "200L"）。
    /// 数値は小数点以下が0なら整数表記にする（"200.0L"ではなく"200L"）。
    public var formatted: String {
        let numberText: String
        if value == value.rounded() {
            numberText = String(Int(value))
        } else {
            numberText = String(value)
        }
        return "\(numberText)\(unit)"
    }
}

public enum FactsCatalogError: Error, LocalizedError, Equatable {
    case fileNotFound(String)
    case decodeFailed(String)
    case unknownFactID(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let n): return "facts.jsonが見つかりません: \(n)"
        case .decodeFailed(let r): return "facts.jsonの解析に失敗: \(r)"
        case .unknownFactID(let id): return "facts.jsonに未定義のfact id: \(id)"
        }
    }
}

/// facts.json のロードと、カードのfactRefsとの突合を行う。
public enum FactsCatalog {

    public static func load(from url: URL) throws -> [String: FactRecord] {
        let data = try Data(contentsOf: url)
        do {
            let records = try JSONDecoder().decode([FactRecord].self, from: data)
            return Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
        } catch {
            throw FactsCatalogError.decodeFailed("\(error)")
        }
    }

    public static func load(from bundle: Bundle, resource: String = "facts") throws -> [String: FactRecord] {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw FactsCatalogError.fileNotFound("\(resource).json")
        }
        return try load(from: url)
    }

    /// カード1枚のfactRefsをfactsカタログと突合する。値がanswerに含まれない/factIDが未定義なら違反を返す。
    public static func crossCheck(card: CardDefinition, facts: [String: FactRecord]) -> [String] {
        var violations: [String] = []
        for refID in card.factRefs {
            guard let fact = facts[refID] else {
                violations.append("[\(card.id)] factRefs未定義: \(refID)")
                continue
            }
            if !card.answer.contains(fact.formatted) {
                violations.append("[\(card.id)] answerに期待値\(fact.formatted)(fact:\(refID))が含まれない")
            }
        }
        return violations
    }

    public static func crossCheck(cards: [CardDefinition], facts: [String: FactRecord]) -> [String] {
        cards.flatMap { crossCheck(card: $0, facts: facts) }
    }
}
