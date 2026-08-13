import SwiftUI
import SwiftData

/// きょうの学習（ホーム）。復習キュー＋新規カード。試験日カウントダウン・ペース判定。
/// spec-v1.0.md §画面構成 1
struct TodayView: View {
    @Environment(DeckRepository.self) private var deck
    @Environment(EntitlementStore.self) private var store
    @Environment(AppSettingsStore.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Query private var progresses: [CardProgress]

    @State private var showLearn = false
    @State private var showPaywall = false
    @State private var queue: [StudyQueueBuilder.QueueItem] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    examCountdownCard
                    queueCard
                }
                .padding()
            }
            .navigationTitle("電工二種 暗記カード")
            .task { rebuildQueue() }
            .onChange(of: progresses.count) { rebuildQueue() }
            .fullScreenCover(isPresented: $showLearn) {
                LearnFlowView(queue: queue) {
                    showLearn = false
                    rebuildQueue()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var examCountdownCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let days = settings.daysUntilExam {
                Text(days >= 0 ? "試験まであと\(days)日" : "試験日が過ぎています")
                    .font(.title3.bold())
                let onTrack = ExamPace.isOnTrack(
                    remainingNewCards: deck.orderedCardIDs.count - progresses.filter(\.isIntroduced).count,
                    daysUntilExam: max(days, 0),
                    currentNewCardsPerDay: 20
                )
                Text(onTrack ? "現在のペースなら間に合います" : "ペースが遅れ気味です。1日の枚数を増やしましょう")
                    .font(.subheadline)
                    .foregroundStyle(onTrack ? .secondary : CardTheme.accent)
                if ExamPace.isCramming(daysUntilExam: max(days, 0)) {
                    Label("詰め込みモード：復習を優先しています", systemImage: "bolt.fill")
                        .font(.caption.bold())
                        .foregroundStyle(CardTheme.accent)
                }
            } else {
                Text("試験日を設定するとペースが分かります")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(CardTheme.chipBG, in: RoundedRectangle(cornerRadius: 16))
    }

    private var queueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("きょうの学習キュー: \(queue.count)枚")
                .font(.headline)
            Button {
                if queue.isEmpty {
                    if !store.isEntitled { showPaywall = true }
                } else {
                    showLearn = true
                }
            } label: {
                Text(queue.isEmpty ? "本日のキューはありません" : "学習をはじめる")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(queue.isEmpty)
            .accessibilityIdentifier("start_learning_button")

            if !store.isEntitled {
                Button("すべてのカードを解放する") { showPaywall = true }
                    .font(.footnote)
                    .accessibilityIdentifier("open_paywall_button")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func rebuildQueue() {
        let today = Date()
        let progressByID = Dictionary(uniqueKeysWithValues: progresses.map { ($0.cardID, $0) })
        let dueIDs = progresses
            .filter { $0.isIntroduced && ($0.dueDate ?? .distantPast) <= today }
            .map(\.cardID)
        let notIntroduced = deck.orderedCardIDs.filter { progressByID[$0]?.isIntroduced != true }

        queue = StudyQueueBuilder.buildQueue(
            dueCardIDs: dueIDs,
            notIntroducedCardIDsInOrder: notIntroduced,
            daysUntilExam: settings.daysUntilExam,
            isPro: store.isEntitled,
            freeAllowedCardIDs: deck.freeAllowedCardIDs,
            alreadyStudiedTodayCount: settings.studiedTodayCount
        )
    }
}
