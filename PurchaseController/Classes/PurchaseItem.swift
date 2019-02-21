//
//  PurchaseItem.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import StoreKit
import SwiftyStoreKit

public struct PurchaseItem {
    let productId: String
    let quantity: Int
    let product: SKProduct
    let transaction: PaymentTransaction
    let originalTransaction: PaymentTransaction?
    
    init(purchaseDeatils: PurchaseDetails) {
        self.productId = purchaseDeatils.productId
        self.product = purchaseDeatils.product
        self.quantity = purchaseDeatils.quantity
        self.transaction = purchaseDeatils.transaction
        self.originalTransaction = purchaseDeatils.originalTransaction
    }
    
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
    func makeItems(with persistance: PurchasePersistor) -> [PurchaseItem] {
        return self.compactMap { (purchase) -> PurchaseItem? in
            return PurchaseItem.create(with: purchase, persistance: persistance)
        }
    }
}

extension PurchaseItem: Hashable {
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
