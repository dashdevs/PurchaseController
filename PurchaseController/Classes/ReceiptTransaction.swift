//
//  ReceiptTransaction.swift
//  PurchaseController
//
//  Created by Vlad Arsenyuk on 5/17/19.
//

import StoreKit
import SwiftyStoreKit

/// Item describes payment transaction object
public struct ReceiptTransaction: PaymentTransaction {
    /// Purchase transaction date
    public var transactionDate: Date?
    /// Purchase transaction state: SKPaymentTransactionState
    public var transactionState: SKPaymentTransactionState
    /// Purchase transaction identifier
    public var transactionIdentifier: String?
    /// Downloadable content associated with a purchase
    public var downloads: [SKDownload]
}
