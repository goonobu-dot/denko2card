import XCTest
import SwiftUI
@testable import Denko2Card

/// 図解テンプレ15種×代表パラメータをPNGとしてdocs/preview/へ書き出す検収テスト。
/// spec-v1.0.md §テスト「検収PNG: 図解テンプレ15種×代表カードをdocs/preview/に書き出し（Fable人の目QA用）」
@MainActor
final class HintTemplatePreviewExportTests: XCTestCase {

    /// このテストファイル自身の絶対パスからリポジトリルートを逆算する。
    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Denko2CardTests
            .deletingLastPathComponent() // repo root
    }

    private var previewDir: URL {
        repoRoot.appendingPathComponent("docs/preview", isDirectory: true)
    }

    private func representativeSamples() throws -> [CardDefinition] {
        let cards = try DeckLoader.loadAll(from: Bundle(for: DeckRepository.self))
        var byTemplate: [String: CardDefinition] = [:]
        for card in cards where byTemplate[card.hintImage.template] == nil {
            byTemplate[card.hintImage.template] = card
        }
        return byTemplate.values.sorted { $0.hintImage.template < $1.hintImage.template }
    }

    func testExportAllTemplatePreviews() throws {
        try FileManager.default.createDirectory(at: previewDir, withIntermediateDirectories: true)
        let samples = try representativeSamples()
        XCTAssertEqual(samples.count, 15, "15種全テンプレの代表カードが揃っていること")

        var exportedFiles: [String] = []
        for card in samples {
            let view = HintImageView(spec: card.hintImage)
                .frame(width: 700, height: 420)
                .background(Color.white)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2.0
            guard let uiImage = renderer.uiImage, let data = uiImage.pngData() else {
                XCTFail("\(card.hintImage.template): PNGレンダリングに失敗")
                continue
            }
            let fileURL = previewDir.appendingPathComponent("\(card.hintImage.template).png")
            try data.write(to: fileURL)
            exportedFiles.append(fileURL.lastPathComponent)
            XCTAssertGreaterThan(data.count, 0)
        }
        XCTAssertEqual(exportedFiles.count, 15)
    }
}
