import Foundation
import Observation

/// 起動時にResources/deck/*.jsonを読み込み、カード定義をメモリ保持するリポジトリ。
/// デッキ本体は別エージェント差し替え予定のため、読み込み経路をここに一本化しておく。
@MainActor
@Observable
final class DeckRepository {
    private(set) var cardsByID: [String: CardDefinition] = [:]
    private(set) var orderedCardIDs: [String] = []
    private(set) var loadError: String?

    init(bundle: Bundle = .main) {
        load(from: bundle)
    }

    func load(from bundle: Bundle) {
        do {
            let cards = try DeckLoader.loadAll(from: bundle)
            cardsByID = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })
            // 学習順＝試験科目順（器具・材料→図記号・複線図→法令・理論）。ファイル名のアルファベット順に依存すると
            // 先頭科目が変わり、無料枠（最初の科目の最初のトピック）と交差せず初回キューが0枚になる
            let subjectOrder: [Subject] = [.kizai, .zumen, .houki]
            orderedCardIDs = subjectOrder.flatMap { subj in
                cards.filter { $0.subject == subj }.map(\.id)
            }
            loadError = nil
        } catch {
            loadError = error.localizedDescription
            cardsByID = [:]
            orderedCardIDs = []
        }
    }

    func card(for id: String) -> CardDefinition? { cardsByID[id] }

    func cardIDs(subject: Subject) -> [String] {
        orderedCardIDs.filter { cardsByID[$0]?.subject == subject }
    }

    var freeAllowedCardIDs: Set<String> {
        Set(orderedCardIDs.filter { id in
            guard let card = cardsByID[id] else { return false }
            return StudyLimiter.isCardFree(subject: card.subject, topic: card.topic)
        })
    }
}
