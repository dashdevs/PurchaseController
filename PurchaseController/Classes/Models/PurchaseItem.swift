//
//  PurchaseItem.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import StoreKit
import SwiftyStoreKit

/// Item describes avaible to purchase object
@objc public final class PurchaseItem: NSObject {
    /// Purchase identifier - unique id of purchase object from appstore connect
    public let productId: String
    /// Amount of purchased items
    public let quantity: Int
    /// StoreKit representation of product
    public let product: SKProduct
    /// Object that describes transaction item
    public let transaction: PaymentTransaction
    /// Object that describes original transaction item (used for subscriptions)
    public let originalTransaction: PaymentTransaction?
    
    /// Data representation of receipt of specific transaction - deprecated
    @available(*, deprecated, message: "Use PurchaseController.decodeIfPresent(sessionReceipt: ReceiptInfo?)")
    public var receiptData: Data? {
        guard let transaction = transaction as? SKPaymentTransaction else { return nil }
        return TransactionReceiptFetcher.directTransactionReceipt(for: transaction)
    }
    
    /// PurchaseItem initializer
    ///
    /// - Parameter purchaseDeatils: SwiftyStoreKit representation of purchased product
    init(purchaseDeatils: PurchaseDetails) {
        self.productId = purchaseDeatils.productId
        self.product = purchaseDeatils.product
        self.quantity = purchaseDeatils.quantity
        self.transaction = purchaseDeatils.transaction
        self.originalTransaction = purchaseDeatils.originalTransaction
    }
    
    /// PurchaseItem initializer
    ///
    /// - Parameters:
    ///   - productId: Purchase identifier - unique id of purchase from appstore connect
    ///   - quantity: Amount of purchased items
    ///   - product: StoreKit representation of product
    ///   - transaction: Object describes transaction item
    ///   - originalTransaction: Object describes original transaction item (used for subscriptions)
    init(productId: String,
         quantity: Int,
         product: SKProduct,
         transaction: PaymentTransaction,
         originalTransaction: PaymentTransaction?) {
        self.productId = productId
        self.product = product
        self.quantity = quantity
        self.transaction = transaction
        self.originalTransaction = originalTransaction
    }
    
    /// Function for purchase creation
    ///
    /// - Parameters:
    ///   - purchase: SwiftyStoreKit restored product
    ///   - persistance: Object that conforms to persistance protocol
    /// - Returns: Describes item available to purchase
    static func create(with purchase: Purchase,
                       persistance: PurchasePersistor) -> PurchaseItem? {
        guard let product = persistance.fetchProducts().first(where: { $0.productIdentifier == purchase.productId}) else {
            return nil
        }
        return PurchaseItem(productId: purchase.productId,
                            quantity: purchase.quantity,
                            product: product,
                            transaction: purchase.transaction,
                            originalTransaction: purchase.originalTransaction)
    }
    
    /// Function for purchase creation
    ///
    /// - Parameters:
    ///   - inApp: decoded object from receipt
    ///   - persistance: Object that conforms to persistance protocol
    /// - Returns: Describes item available to purchase
    static func create(with inApp: InAppPurchase,
                       persistance: PurchasePersistor) -> PurchaseItem? {
        guard let product = persistance.fetchProducts().first(where: { $0.productIdentifier == inApp.productId}) else {
            return nil
        }
        return PurchaseItem(productId: inApp.productId,
                            quantity: inApp.quantity,
                            product: product,
                            transaction: inApp.purchaseTransaction,
                            originalTransaction: inApp.originalPurchaseTransaction)
    }
    
    /// Function for purchase creation
    ///
    /// - Parameters:
    ///   - transaction: StoreKit restored product transaction
    ///   - persistance: Object that conforms to persistance protocol
    /// - Returns: Describes item available to purchase
    static func create(with transaction: SKPaymentTransaction,
                       persistance: PurchasePersistor) -> PurchaseItem? {
        guard let product = persistance.fetchProducts().first(where: { $0.productIdentifier == transaction.payment.productIdentifier}) else {
            return nil
        }
        return PurchaseItem(productId: transaction.payment.productIdentifier,
                            quantity: transaction.payment.quantity,
                            product: product,
                            transaction: transaction,
                            originalTransaction: transaction.original)
    }
    
    /// Function for transaction completion
    /// Transaction will be presented in receipt until finished
    public func completeTransaction() {
        SwiftyStoreKit.finishTransaction(transaction)
    }
    
    /// Function for original transaction completion
    /// Original transaction appears after restoring or renewal (for subscriptions)
    /// Transaction will be presented in receipt until finished
    ///
    /// - Throws: an PurchaseError.noOriginalTransactionData error when original transaction does not exist
    public func completeOriginalTransaction() throws {
        guard let original = originalTransaction else {
            throw PurchaseError.noOriginalTransactionData.nsError
        }
        SwiftyStoreKit.finishTransaction(original)
    }
    
    // MARK: - Hashable
    
    /// Compares two PurchaseItem using productId, transactionIdentifier and product.productIdentifier
    ///
    /// - Parameters:
    ///   - lhs: left value to compare
    ///   - rhs: right value to compare
    /// - Returns: Equatable value
    public static func == (lhs: PurchaseItem, rhs: PurchaseItem) -> Bool {
        return lhs.productId == rhs.productId &&
            lhs.transaction.transactionIdentifier == rhs.transaction.transactionIdentifier &&
            lhs.product.productIdentifier == rhs.product.productIdentifier
    }    
}

extension Collection where Element == Purchase {
    internal func makeItems(with persistance: PurchasePersistor) -> [PurchaseItem] {
        return self.compactMap { (purchase) -> PurchaseItem? in
            return PurchaseItem.create(with: purchase, persistance: persistance)
        }
    }
}

extension Collection where Element == InAppPurchase {
    internal func makeItems(with persistance: PurchasePersistor) -> [PurchaseItem] {
        return self.compactMap { (purchase) -> PurchaseItem? in
            return PurchaseItem.create(with: purchase, persistance: persistance)
        }
    }
}

extension Collection where Element == SKPaymentTransaction {
    internal func makeItems(with persistance: PurchasePersistor) -> [PurchaseItem] {
        return self.compactMap { (transaction) -> PurchaseItem? in
            return PurchaseItem.create(with: transaction, persistance: persistance)
        }
    }
}
