import Foundation
import StoreKit
import Observation

/// StoreKit 2 の権利管理ストア。買い切り(unlock)のみを扱う。
/// 外部課金SDKは使わない（ゼロコスト原則）。
@MainActor
@Observable
final class EntitlementStore {
    let productIDs: [String]

    private(set) var products: [String: Product] = [:]
    private(set) var ownedProductIDs: Set<String> = []
    private(set) var isLoadingProducts = false
    private(set) var isProcessing = false
    var errorMessage: String?

    private nonisolated(unsafe) var updatesTask: Task<Void, Never>?

    init(productIDs: [String] = ProductIDs.all) {
        self.productIDs = productIDs
        updatesTask = Task { [weak self] in
            await self?.observeTransactionUpdates()
        }
    }

    deinit { updatesTask?.cancel() }

    func start() async {
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        guard !productIDs.isEmpty else { return }
        for attempt in 0..<3 {
            do {
                let fetched = try await Product.products(for: productIDs)
                if !fetched.isEmpty {
                    products = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
                    return
                }
            } catch {
                // 一時的な取得失敗の可能性が高いため既存productsは保持して再試行する。
            }
            if attempt < 2 {
                try? await Task.sleep(nanoseconds: UInt64(500_000_000 * (attempt + 1)))
            }
        }
    }

    func refreshEntitlements() async {
        var owned: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.revocationDate == nil else { continue }
            if let expiration = transaction.expirationDate, expiration < Date() { continue }
            owned.insert(transaction.productID)
        }
        ownedProductIDs = owned
    }

    var isEntitled: Bool { !ownedProductIDs.isEmpty }

    func purchase(productID: String) async {
        if products[productID] == nil {
            await loadProducts()
        }
        guard let product = products[productID] else {
            errorMessage = "商品情報を取得できませんでした"
            return
        }
        isProcessing = true
        defer { isProcessing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                } else {
                    errorMessage = "購入の検証に失敗しました"
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "承認待ちです"
            @unknown default:
                break
            }
        } catch {
            errorMessage = "購入処理に失敗しました"
        }
    }

    func restore() async {
        isProcessing = true
        defer { isProcessing = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = "復元に失敗しました"
        }
    }

    private func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            await transaction.finish()
            await refreshEntitlements()
        }
    }

    #if DEBUG
    func debugSetOwned(_ ids: Set<String>) { ownedProductIDs = ids }
    #endif
}
