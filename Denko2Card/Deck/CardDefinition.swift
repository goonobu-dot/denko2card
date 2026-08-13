import Foundation

/// 3科目（第二種電気工事士 試験区分に対応）。shikaku5-specs.md §1
public enum Subject: String, Sendable, CaseIterable, Identifiable {
    case kizai          // ①器具・材料
    case zumen          // ②図記号・複線図
    case houki          // ③法令・理論

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .kizai: return "器具・材料"
        case .zumen: return "図記号・複線図"
        case .houki: return "法令・理論"
        }
    }

    /// デッキ執筆側が英語キー・日本語表記のどちらで書いても読めるようにする寛容デコード。
    public init?(deckValue raw: String) {
        switch raw {
        case "kizai", "器具・材料", "器材":
            self = .kizai
        case "zumen", "図記号・複線図", "図面", "図記号":
            self = .zumen
        case "houki", "法令・理論", "法規", "法令":
            self = .houki
        default:
            return nil
        }
    }
}

extension Subject: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let value = Subject(deckValue: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "未知のsubject: \(raw)"
            )
        }
        self = value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// 図解ヒントのテンプレ指定。paramsは文字列キー・文字列値のみ（デッキ執筆側が書きやすいよう単純化）。
/// 数値が必要なテンプレは文字列をDouble()等でパースする。
public struct HintImageSpec: Codable, Sendable, Equatable {
    public let template: String
    public let params: [String: String]

    public init(template: String, params: [String: String]) {
        self.template = template
        self.params = params
    }
}

/// カードJSONスキーマ（spec-v1.0.md §デッキ）。
/// `{id, subject, topic, question, answer, choices[3], hintImage:{template, params}, goro, goroNote, source, tags[]}`
public struct CardDefinition: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let subject: Subject
    public let topic: String
    public let question: String
    public let answer: String
    public let choices: [String]
    public let hintImage: HintImageSpec
    public let goro: String
    public let goroNote: String
    /// 出典（政令・規則の条項番号や公表基準値のみ。書籍名は不可＝法的リスク対策）
    public let source: String
    public let tags: [String]
    /// facts.jsonの数値と突合するfact id一覧（任意項目・省略時は空配列＝突合対象外）。
    /// 指定した場合、facts.json記載の値（単位つき文字列）がanswerに含まれることをテストで検証する。
    public let factRefs: [String]

    public init(
        id: String, subject: Subject, topic: String, question: String, answer: String,
        choices: [String], hintImage: HintImageSpec, goro: String, goroNote: String,
        source: String, tags: [String], factRefs: [String] = []
    ) {
        self.id = id
        self.subject = subject
        self.topic = topic
        self.question = question
        self.answer = answer
        self.choices = choices
        self.hintImage = hintImage
        self.goro = goro
        self.goroNote = goroNote
        self.source = source
        self.tags = tags
        self.factRefs = factRefs
    }

    private enum CodingKeys: String, CodingKey {
        case id, subject, topic, question, answer, choices, hintImage, goro, goroNote, source, tags, factRefs
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        subject = try c.decode(Subject.self, forKey: .subject)
        topic = try c.decode(String.self, forKey: .topic)
        question = try c.decode(String.self, forKey: .question)
        answer = try c.decode(String.self, forKey: .answer)
        choices = try c.decode([String].self, forKey: .choices)
        hintImage = try c.decode(HintImageSpec.self, forKey: .hintImage)
        goro = try c.decode(String.self, forKey: .goro)
        goroNote = try c.decode(String.self, forKey: .goroNote)
        source = try c.decode(String.self, forKey: .source)
        tags = try c.decode([String].self, forKey: .tags)
        factRefs = try c.decodeIfPresent([String].self, forKey: .factRefs) ?? []
    }
}

/// デッキファイル全体（Resources/deck/*.json の1ファイル分）
public struct DeckFile: Codable, Sendable {
    public let cards: [CardDefinition]

    public init(cards: [CardDefinition]) {
        self.cards = cards
    }
}

public extension CardDefinition {
    /// H3ヒント用の3択（正解1＋誤答2）。カードIDをシードにした決定論シャッフルで、
    /// 表示のたびに並びが変わらない（=テスト可能・ユーザーの位置記憶にも一貫性）。
    func threeChoicesIncludingAnswer() -> [String] {
        var seed: UInt64 = 0xA5A5_5A5A
        for b in id.utf8 { seed = seed &* 31 &+ UInt64(b) }
        func next() -> UInt64 { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return seed >> 33 }
        var distractors = choices
        // 誤答3つから2つを決定論選択
        if distractors.count > 2 {
            let dropIndex = Int(next() % UInt64(distractors.count))
            distractors.remove(at: dropIndex)
        }
        var options = Array(distractors.prefix(2)) + [answer]
        // 決定論シャッフル
        for i in stride(from: options.count - 1, to: 0, by: -1) {
            let j = Int(next() % UInt64(i + 1))
            options.swapAt(i, j)
        }
        return options
    }
}
