import Foundation

public enum DeckLoaderError: Error, LocalizedError, Equatable {
    case fileNotFound(String)
    case decodeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let name): return "デッキファイルが見つかりません: \(name)"
        case .decodeFailed(let reason): return "デッキファイルの解析に失敗しました: \(reason)"
        }
    }
}

/// Resources/deck/*.json を読み込みCardDefinitionへデコードする。
/// 本デッキは別エージェントが執筆中のため、開発中はサンプル30枚（denko2_sample.json）で動作させ、
/// スキーマ互換のまま差し替えられるようにする（spec-v1.0.md §デッキ）。
public enum DeckLoader {

    /// バンドル内の全デッキJSONファイルを読み込みマージする。
    /// XcodeGenは `Denko2Card/Resources/deck/*.json` をバンドル直下にコピーするため、
    /// サブディレクトリではなくファイル名パターン（`facts.json`以外の`*.json`）で判別する。
    public static func loadAll(from bundle: Bundle) throws -> [CardDefinition] {
        guard let urls = bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) else {
            throw DeckLoaderError.fileNotFound("*.json")
        }
        let deckURLs = urls.filter { $0.lastPathComponent != "facts.json" }
        var all: [CardDefinition] = []
        let decoder = JSONDecoder()
        for url in deckURLs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let data = try Data(contentsOf: url)
            do {
                let file = try decoder.decode(DeckFile.self, from: data)
                all.append(contentsOf: file.cards)
            } catch {
                throw DeckLoaderError.decodeFailed("\(url.lastPathComponent): \(error)")
            }
        }
        return all
    }

    /// 単一ファイルから読み込む（テスト用）
    public static func load(from url: URL) throws -> [CardDefinition] {
        let data = try Data(contentsOf: url)
        do {
            let file = try JSONDecoder().decode(DeckFile.self, from: data)
            return file.cards
        } catch {
            throw DeckLoaderError.decodeFailed("\(url.lastPathComponent): \(error)")
        }
    }
}
