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
    let originaPurchaseDate: Date?
    let originalPurchaseDatePst: Date?
    let webOrderLineItemId: String?
    let isTrialPeriod: String
    let isInIntroOfferPeriod: String?
    let expiresDate: Date?
    let expiresDateMs: Date?
    let expiresDatePst: Date?
    let purchaseDate: Date?
    let purchaseDatePst: Date?
    
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
        expiresDate = Date()
        expiresDatePst =  Date()
        originaPurchaseDate = Date()
        originalPurchaseDatePst = Date()
        purchaseDate = Date()
        purchaseDatePst = Date()
    }
    
}
