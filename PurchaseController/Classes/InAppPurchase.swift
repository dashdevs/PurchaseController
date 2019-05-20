//
//  InAppPurchase.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation
import SwiftyStoreKit

/// Representation of inapp purchase
struct InAppPurchase: Codable {
    /// The number of items purchased.
    let quantity: Int
    /// The product identifier of the item that was purchased.
    let productId: String
    /// The transaction identifier of the item that was purchased.
    let transactionId: String
    /// For a transaction that restores a previous transaction, the transaction identifier of the original transaction. Otherwise, identical to the transaction identifier.
    let originalTransactionId: String?
    /// The date and time that the item was purchased.
    let purchaseDateMs: Date?
    /// For a transaction that restores a previous transaction, the date of the original transaction.
    let originalPurchaseDateMs: Date?
    /// For a transaction that restores a previous transaction, the date of the original transaction.
    let originaPurchaseDate: String?
    /// For a transaction that restores a previous transaction, the date of the original transaction.
    let originalPurchaseDatePst: String?
    /// The primary key for identifying subscription purchases.
    let webOrderLineItemId: String?
    /// For a subscription, whether or not it is in the free trial period.
    let isTrialPeriod: Bool?
    /// For an auto-renewable subscription, whether or not it is in the introductory price period.
    let isInIntroOfferPeriod: Bool?
    /// The date that the app receipt expires.
    let expiresDate: String?
    /// The date that the app receipt expires.
    let expiresDateMs: Date?
    /// The date that the app receipt expires.
    let expiresDatePst: String?
    /// The date and time that the item was purchased.
    let purchaseDate: String?
    /// The date and time that the item was purchased.
    let purchaseDatePst: String?
    
    /// Payment transaction object
    public var purchaseTransaction: PaymentTransaction {
        return ReceiptTransaction(transactionDate: purchaseDateMs,
                                  transactionState: .purchased,
                                  transactionIdentifier: transactionId,
                                  downloads: [])
    }
    
    /// Original payment transaction object
    public var originalPurchaseTransaction: PaymentTransaction {
        return ReceiptTransaction(transactionDate: originalPurchaseDateMs,
                                  transactionState: .purchased,
                                  transactionIdentifier: originalTransactionId,
                                  downloads: [])
    }
    
    enum CodingKeys: String, CodingKey {
        case quantity
        case productId = "product_id"
        case transactionId = "transaction_id"
        case originalTransactionId = "original_transaction_id"
        case purchaseDateMs = "purchase_date_ms"
        case purchaseDate = "purchase_date"
        case purchaseDatePst = "purchase_date_pst"
        case originalPurchaseDateMs = "original_purchase_date_ms"
        case originaPurchaseDate = "original_purchase_date"
        case originalPurchaseDatePst = "original_purchase_date_pst"
        case expiresDateMs = "expires_date_ms"
        case webOrderLineItemId = "web_order_line_item_id"
        case isTrialPeriod = "is_trial_period"
        case isInIntroOfferPeriod = "is_in_intro_offer_period"
        case expiresDate = "expires_date"
        case expiresDatePst = "expires_date_pst"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        quantity = Int(try values.decode(String.self, forKey: .quantity)) ?? 0
        productId = try values.decode(String.self, forKey: .productId)
        transactionId = try values.decode(String.self, forKey: .transactionId)
        originalTransactionId = try values.decode(String.self, forKey: .originalTransactionId)
        if let purchaseDateString = try? values.decode(String.self, forKey: .purchaseDateMs),
            let seconds = TimeInterval(millisecondsString: purchaseDateString) {
            purchaseDateMs = Date(timeIntervalSince1970: seconds)
        } else {
            purchaseDateMs = nil
        }
        if let originalPurchaseDate = try? values.decode(String.self, forKey: .originalPurchaseDateMs),
            let seconds = TimeInterval(millisecondsString: originalPurchaseDate) {
            originalPurchaseDateMs = Date(timeIntervalSince1970: seconds)
        } else {
            originalPurchaseDateMs = nil
        }
        if let expiresDateString = try? values.decode(String.self, forKey: .expiresDateMs),
            let seconds = TimeInterval(millisecondsString: expiresDateString) {
            expiresDateMs = Date(timeIntervalSince1970: seconds)
        } else {
            expiresDateMs = nil
        }
        webOrderLineItemId = try? values.decode(String.self, forKey: .webOrderLineItemId)
        isTrialPeriod = Bool(try values.decode(String.self, forKey: .isTrialPeriod))
        if let isInIntroOfferPeriodString = try? values.decode(String.self, forKey: .isInIntroOfferPeriod) {
            isInIntroOfferPeriod = Bool(isInIntroOfferPeriodString)
        } else {
            isInIntroOfferPeriod = nil
        }
        expiresDate =  try? values.decode(String.self, forKey: .expiresDate)
        expiresDatePst =  try? values.decode(String.self, forKey: .expiresDatePst)
        originaPurchaseDate = try values.decode(String.self, forKey: .originaPurchaseDate)
        originalPurchaseDatePst = try values.decode(String.self, forKey: .originalPurchaseDatePst)
        purchaseDate = try values.decode(String.self, forKey: .purchaseDate)
        purchaseDatePst = try values.decode(String.self, forKey: .purchaseDatePst)
    }
    
}

extension TimeInterval {
    /// Use to convert TimeInterval to seconds
    private struct Constants {
        static let thousand: Double = 1000
    }
    
    init?(millisecondsString: String) {
        guard let milliseconds = TimeInterval(millisecondsString) else {
            return nil
        }
        self = milliseconds / Constants.thousand
    }
}
