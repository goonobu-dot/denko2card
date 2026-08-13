import SwiftUI

/// ペイウォール。買い切り「全解放パック」¥1,800のみ（サブスクは作らない方針）。
struct PaywallView: View {
    var allowsDismiss: Bool = true
    var onUnlocked: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementStore.self) private var store

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "bolt.fill").font(.system(size: 44)).foregroundStyle(CardTheme.accent)
                Text("すべてのカードを無制限に").font(.title2.bold())
                Text("器具・材料、図記号・複線図、法令・理論の全340枚と、試験日ペース管理、弱点マップが使えます。")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 2) {
                    Text(billedAmountText).font(.title3.bold())
                    Text("全解放パック（買い切り）").font(.caption).foregroundStyle(.secondary)
                    Text("一度の購入でずっと使える").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Button {
                    Task {
                        await store.purchase(productID: ProductIDs.unlock)
                        if store.isEntitled { closeIfPossible() }
                    }
                } label: {
                    VStack(spacing: 2) {
                        Text(billedAmountText).font(.title3.bold())
                        Text("購入する").font(.footnote)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .accessibilityIdentifier("paywall_purchase")
                .disabled(store.isProcessing)

                Button("購入を復元") {
                    Task {
                        await store.restore()
                        if store.isEntitled { closeIfPossible() }
                    }
                }
                .font(.footnote)
                .accessibilityIdentifier("paywall_restore")

                Text("買い切り価格のため自動更新や継続課金はありません。合格を保証するものではありません。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 16) {
                    Link("利用規約（EULA）",
                         destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    Link("プライバシーポリシー",
                         destination: URL(string: "https://goonobu-dot.github.io/denko2card-public/privacy.html")!)
                }
                .font(.caption2)
                .accessibilityIdentifier("paywall_legal_links")
                Spacer()
            }
            .padding()
            .toolbar {
                if allowsDismiss {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") { closeIfPossible() }
                    }
                }
            }
        }
    }

    private func closeIfPossible() {
        onUnlocked?()
        dismiss()
    }

    private var billedAmountText: String {
        store.products[ProductIDs.unlock]?.displayPrice ?? "¥1,800"
    }
}
