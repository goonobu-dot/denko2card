import SwiftUI
import SwiftData

/// カード学習画面。問題提示→ヒント段階開示→答え→自己評価3択。
/// デザインはsample-cards/の5枚（紙色背景・図解パネル・語呂帯・下部大ボタン）に準拠。
/// spec-v1.0.md §学習フロー
struct LearnCardView: View {
    let card: CardDefinition
    let onComplete: (SelfEvaluation, Int) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var hintLevel: HintLevel = .h0
    @State private var startLevel: HintLevel = .h1
    @State private var showAnswer = false
    @State private var didLoadProgress = false

    var body: some View {
        ZStack {
            CardTheme.paper.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(card.question)
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundStyle(CardTheme.ink)

                        if hintLevel >= .h1 {
                            HintImageView(spec: card.hintImage)
                        }

                        if hintLevel >= .h2 {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("語呂：\(card.goro)").font(.title3.bold()).foregroundStyle(CardTheme.ink)
                                Text(card.goroNote).font(.subheadline.weight(.semibold)).foregroundStyle(CardTheme.sub)
                            }
                        }

                        if hintLevel >= .h3 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("3択").font(.headline).foregroundStyle(CardTheme.sub)
                                // 正解＋誤答2つ（カードIDで決定論シャッフル＝テスト可能・毎回同じ並び）
                                ForEach(card.threeChoicesIncludingAnswer(), id: \.self) { choice in
                                    Text("・\(choice)").font(.body)
                                }
                            }
                        }

                        if showAnswer {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("答え").font(.headline).foregroundStyle(CardTheme.sub)
                                Text(card.answer).font(.title3.bold()).foregroundStyle(CardTheme.accent)
                            }
                            .accessibilityIdentifier("answer_text")
                        }
                    }
                    .padding(.vertical, 8)
                }
                Spacer(minLength: 0)
                footer
            }
            .padding()
        }
        .task {
            guard !didLoadProgress else { return }
            didLoadProgress = true
            loadStartLevel()
        }
    }

    private var header: some View {
        HStack {
            Text("電工二種 › \(card.subject.displayName)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CardTheme.sub)
            Spacer()
            if hintLevel != .h0 {
                Text("ヒント \(hintLevel.rawValue) / 3")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(CardTheme.chipBG, in: Capsule())
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        if showAnswer {
            HStack(spacing: 12) {
                evalButton("ラクに思い出せた", .easy)
                evalButton("ヒントのおかげ", .helped)
                evalButton("無理だった", .couldNotRecall)
            }
        } else {
            HStack(spacing: 12) {
                Button {
                    onComplete2(evaluation: .easy)
                } label: {
                    Text("わかる").frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("know_it_button")

                if hintLevel < .h3 {
                    Button {
                        hintLevel = HintStateMachine.advance(current: hintLevel, startLevel: startLevel)
                    } label: {
                        Text("ヒント").frame(maxWidth: .infinity).padding()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("hint_button")
                } else {
                    Button {
                        showAnswer = true
                    } label: {
                        Text("答えを見る").frame(maxWidth: .infinity).padding()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("reveal_answer_button")
                }
            }
        }
    }

    private func evalButton(_ title: String, _ evaluation: SelfEvaluation) -> some View {
        Button {
            onComplete(evaluation, hintLevel.rawValue)
        } label: {
            Text(title).font(.footnote).frame(maxWidth: .infinity).padding(10)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("eval_\(evaluation.rawValue)")
    }

    /// 「わかる」ボタンは即答え表示に切り替える（自己評価はその後で行う）。
    private func onComplete2(evaluation: SelfEvaluation) {
        showAnswer = true
    }

    private func loadStartLevel() {
        let cardID = card.id
        let descriptor = FetchDescriptor<CardProgress>(predicate: #Predicate { $0.cardID == cardID })
        if let existing = try? modelContext.fetch(descriptor).first {
            startLevel = existing.startHintLevel
        } else {
            startLevel = .h1
        }
    }
}
