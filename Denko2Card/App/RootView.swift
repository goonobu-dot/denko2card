import SwiftUI

struct RootView: View {
    private enum Tab: Hashable {
        case today, progress, settings
    }

    @State private var selectedTab: Tab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("きょうの学習", systemImage: "sun.max.fill") }
                .accessibilityIdentifier("tab_today")
                .tag(Tab.today)

            ProgressHomeView()
                .tabItem { Label("進捗", systemImage: "chart.bar.fill") }
                .accessibilityIdentifier("tab_progress")
                .tag(Tab.progress)

            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
                .accessibilityIdentifier("tab_settings")
                .tag(Tab.settings)
        }
    }
}
