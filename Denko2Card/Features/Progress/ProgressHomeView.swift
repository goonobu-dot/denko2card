import SwiftUI
import SwiftData

/// 進捗画面: 科目別の卒業率・弱点トピック（ヒント依存度が高い順）・学習日数。
/// spec-v1.0.md §画面構成 3
struct ProgressHomeView: View {
    @Environment(DeckRepository.self) private var deck
    @Environment(AppSettingsStore.self) private var settings
    @Query private var progresses: [CardProgress]

    var body: some View {
        NavigationStack {
            List {
                Section("学習日数") {
                    Label("連続\(settings.streakCount)日", systemImage: "flame.fill")
                }
                Section("科目別 卒業状況") {
                    ForEach(Subject.allCases) { subject in
                        let ids = Set(deck.cardIDs(subject: subject))
                        let subjectProgresses = progresses.filter { ids.contains($0.cardID) }
                        let graduated = subjectProgresses.filter { $0.isGraduated(asOf: Date()) }.count
                        HStack {
                            Text(subject.displayName)
                            Spacer()
                            Text("\(graduated) / \(ids.count) 枚 卒業")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("弱点トピック（ヒント依存度が高い順）") {
                    let weakest = progresses
                        .filter { $0.totalReviews > 0 }
                        .sorted { $0.hintDependencyRate > $1.hintDependencyRate }
                        .prefix(10)
                    if weakest.isEmpty {
                        Text("学習を進めると弱点が表示されます").foregroundStyle(.secondary)
                    } else {
                        ForEach(weakest, id: \.cardID) { progress in
                            if let card = deck.card(for: progress.cardID) {
                                HStack {
                                    Text(card.topic)
                                    Spacer()
                                    Text("\(Int(progress.hintDependencyRate * 100))%")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("進捗")
        }
    }
}
