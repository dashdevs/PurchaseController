//
//  InApp.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

struct InApp: Codable {
    let quantity: String
    let productId: String
    let transactionId: String
    let originalTransactionId: String
    let purchaseDateMs: Date?
    let originalPurchaseDateMs: Date?
    let expiresDateMs: Date?
    let webOrderLineItemId: String?
    let isTrialPeriod: String
    let isInIntroOfferPeriod: String?
    
    enum CodingKeys: String, CodingKey {
        case quantity
        case productId = "product_id"
        case transactionId = "transaction_id"
        case originalTransactionId = "original_transaction_id"
        case purchaseDateMs = "purchase_date_ms"
        case originalPurchaseDateMs = "original_purchase_date_ms"
        case expiresDateMs = "expires_date_ms"
        case webOrderLineItemId = "web_order_line_item_id"
        case isTrialPeriod = "is_trial_period"
        case isInIntroOfferPeriod = "is_in_intro_offer_period"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        quantity = try values.decode(String.self, forKey: .quantity)
        productId = try values.decode(String.self, forKey: .productId)
        transactionId = try values.decode(String.self, forKey: .transactionId)
        originalTransactionId = try values.decode(String.self, forKey: .originalTransactionId)
        if let purchaseDateString = try? values.decode(String.self, forKey: .purchaseDateMs) {
            purchaseDateMs = purchaseDateString.date()
        } else {
            purchaseDateMs = nil
        }
        if let originalPurchaseDate = try? values.decode(String.self, forKey: .originalPurchaseDateMs) {
           originalPurchaseDateMs = originalPurchaseDate.date()
        } else {
            originalPurchaseDateMs = nil
        }
        if let expiresDateString = try? values.decode(String.self, forKey: .expiresDateMs) {
            expiresDateMs = expiresDateString.date()
        } else {
            expiresDateMs = nil
        }
        webOrderLineItemId = try? values.decode(String.self, forKey: .webOrderLineItemId)
        isTrialPeriod = try values.decode(String.self, forKey: .isTrialPeriod)
        isInIntroOfferPeriod = try? values.decode(String.self, forKey: .isInIntroOfferPeriod)
    }
    
}
