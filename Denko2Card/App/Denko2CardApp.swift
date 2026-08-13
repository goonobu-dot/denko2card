import SwiftUI
import SwiftData

@main
struct Denko2CardApp: App {
    let modelContainer: ModelContainer
    @State private var deckRepository = DeckRepository()
    @State private var entitlementStore = EntitlementStore()
    @State private var settingsStore = AppSettingsStore()

    init() {
        do {
            modelContainer = try ModelContainer(for: CardProgress.self)
        } catch {
            fatalError("SwiftData ModelContainerの初期化に失敗: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(deckRepository)
                .environment(entitlementStore)
                .environment(settingsStore)
                .task {
                    await entitlementStore.start()
                }
        }
        .modelContainer(modelContainer)
    }
}
