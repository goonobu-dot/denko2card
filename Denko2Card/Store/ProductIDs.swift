import Foundation

/// ProductID厳守（ios-appstore-shippingスキル §1-1: コードとASC完全一致必須）
/// 本アプリはサブスクを作らない方針のため買い切りのみ（shikaku5-specs.md 共通仕様）。
enum ProductIDs {
    static let unlock = "com.goonobu.denko2card.unlock"
    static let all = [unlock]
}
