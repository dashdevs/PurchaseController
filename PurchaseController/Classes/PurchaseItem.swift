//
//  PurchaseItem.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import StoreKit
import SwiftyStoreKit

/// Item describes avaible to purchase object
public struct PurchaseItem {
    /// Purcahse identifier - unique id of purchase from appstore connect
    let productId: String
    /// Amount of purchased items
    let quantity: Int
    /// SK representation of product
    let product: SKProduct
    /// Object describes item transaction
    let transaction: PaymentTransaction
    /// Object describes original item transaction (used for subscriptions)
    let originalTransaction: PaymentTransaction?
    
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
    ///   - productId: Purcahse identifier - unique id of purchase from appstore connect
    ///   - quantity: Amount of purchased items
    ///   - product: SK representation of product
    ///   - transaction: Object describes item transaction
    ///   - originalTransaction: Object describes original item transaction (used for subscriptions)
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
    ///   - purchase: SwiftyStoreKit Restored product
    ///   - persistance: Object conforms protocol persistance
    /// - Returns: Item describes avaible to purchase object
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
    
}


extension Collection where Element == Purchase {
    internal func makeItems(with persistance: PurchasePersistor) -> [PurchaseItem] {
        return self.compactMap { (purchase) -> PurchaseItem? in
            return PurchaseItem.create(with: purchase, persistance: persistance)
        }
    }
}

extension PurchaseItem: Hashable {
    /// Compares two PurchaseItem according to productId, transactionIdentifier and product.productIdentifier
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
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(productId)
        hasher.combine(product.productIdentifier)
        hasher.combine(transaction.transactionIdentifier)
    }
}
