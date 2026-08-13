import SwiftUI
import StoreKit

/// 設定画面: 試験日・1日の枚数・購入/復元・プライバシー。spec-v1.0.md §画面構成 4
struct SettingsView: View {
    @Environment(AppSettingsStore.self) private var settings
    @Environment(EntitlementStore.self) private var store
    @State private var showPaywall = false
    @State private var examDateEnabled: Bool = false
    @State private var examDate: Date = Date().addingTimeInterval(60 * 24 * 3600)

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section("試験日") {
                    Toggle("試験日を設定する", isOn: $examDateEnabled)
                        .onChange(of: examDateEnabled) { _, enabled in
                            settings.examDate = enabled ? examDate : nil
                        }
                    if examDateEnabled {
                        DatePicker("試験日", selection: $examDate, displayedComponents: .date)
                            .onChange(of: examDate) { _, newValue in
                                settings.examDate = newValue
                            }
                    }
                }

                Section("購入") {
                    if store.isEntitled {
                        Label("解放済み", systemImage: "checkmark.seal.fill")
                    } else {
                        Button("すべてのカードを解放する") { showPaywall = true }
                    }
                    Button("購入を復元") {
                        Task { await store.restore() }
                    }
                }

                Section("免責") {
                    Text("本アプリは合格を保証するものではありません。想起練習・段階ヒントは学習研究で効果が示されている学習手法を参考にしています。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onAppear {
                examDateEnabled = settings.examDate != nil
                if let d = settings.examDate { examDate = d }
            }
        }
    }
}
