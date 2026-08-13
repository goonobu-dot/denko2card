import SwiftUI

/// サンプルカードデザイン（~/Projects/next-app-research/round5-2026-07-16/sample-cards/）に準拠した配色。
/// cards5.swift（scratchpad検証コード）のNSColor値をSwiftUI Colorへ移植したもの。
enum CardTheme {
    static let paper = Color(red: 0.98, green: 0.97, blue: 0.95)
    static let ink = Color(red: 0.13, green: 0.15, blue: 0.20)
    static let accent = Color(red: 0.85, green: 0.33, blue: 0.16)
    static let blue = Color(red: 0.30, green: 0.55, blue: 0.85)
    static let sub = Color(red: 0.45, green: 0.48, blue: 0.54)
    static let chipBG = Color(red: 0.92, green: 0.90, blue: 0.86)
    static let gold = Color(red: 0.78, green: 0.62, blue: 0.22)
}

/// 図解ヒントの共通カードパネル（白背景・角丸・薄い影）。各テンプレはこの中にCanvasで描画する。
struct HintPanel<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .frame(maxWidth: .infinity, minHeight: 260)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
    }
}

/// hintImage.paramsから値を安全に取り出すヘルパー
extension Dictionary where Key == String, Value == String {
    func string(_ key: String, default def: String = "") -> String {
        self[key] ?? def
    }
    func double(_ key: String, default def: Double = 0) -> Double {
        self[key].flatMap(Double.init) ?? def
    }
}
