import SwiftUI
import SwiftData

/// 学習フロー全体（きょうのキューを1枚ずつ回す）。spec-v1.0.md §学習フロー
struct LearnFlowView: View {
    let queue: [StudyQueueBuilder.QueueItem]
    let onFinished: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(DeckRepository.self) private var deck
    @Environment(AppSettingsStore.self) private var settings
    @State private var index = 0

    var body: some View {
        NavigationStack {
            Group {
                if index < queue.count, let card = deck.card(for: queue[index].cardID) {
                    LearnCardView(card: card) { evaluation, hintLevelUsed in
                        recordResult(cardID: card.id, subject: card.subject, evaluation: evaluation, hintLevelUsed: hintLevelUsed)
                        advance()
                    }
                    .id(card.id)
                } else {
                    completionView
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("終了") { onFinished() }
                }
            }
        }
    }

    private var completionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 56)).foregroundStyle(CardTheme.accent)
            Text("きょうの学習は完了です").font(.title2.bold())
            Button("閉じる") { onFinished() }
                .buttonStyle(.borderedProminent)
        }
        .accessibilityIdentifier("learn_completion_view")
    }

    private func advance() {
        index += 1
    }

    private func recordResult(cardID: String, subject: Subject, evaluation: SelfEvaluation, hintLevelUsed: Int) {
        let descriptor = FetchDescriptor<CardProgress>(predicate: #Predicate { $0.cardID == cardID })
        let progress: CardProgress
        if let existing = try? modelContext.fetch(descriptor).first {
            progress = existing
        } else {
            progress = CardProgress(cardID: cardID, subject: subject)
            modelContext.insert(progress)
        }
        progress.applyReview(evaluation: evaluation, hintLevelUsed: hintLevelUsed, reviewedAt: Date())
        settings.incrementStudiedToday()
        settings.recordStudyDayIfNeeded()
    }
}
