//
//  InAppPurchase.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation
import SwiftyStoreKit

/// Representation of inapp purchase
struct InAppPurchase: ReadableDebugStringProtocol {
    
    // MARK: - Properties
    
    /// The number of items purchased.
    let quantity: Int
    /// The product identifier of the item that was purchased.
    let productId: String
    /// The transaction identifier of the item that was purchased.
    let transactionId: String
    /// For a transaction that restores a previous transaction, the transaction identifier of the original transaction. Otherwise, identical to the transaction identifier.
    let originalTransactionId: String?

    /// The date and time that the item was purchased.
    let purchaseDate: Date?
    let purchaseDateMs: Date?
    let purchaseDatePst: Date?

    /// For a transaction that restores a previous transaction, the date of the original transaction.
    let originalPurchaseDate: Date?
    let originalPurchaseDateMs: Date?
    let originalPurchaseDatePst: Date?
    
    /// The date that the app receipt expires.
    let expiresDate: Date?
    let expiresDateMs: Date?
    let expiresDatePst: Date?

    /// For an expired subscription, the reason for the subscription expiration.
    let subscriptionExpirationIntent: Int? // TODO: create an enum for int values
    
    /// For an expired subscription, whether or not Apple is still attempting to automatically renew the subscription.
    let subscriptionRetryFlag: Int? // TODO: create an enum for int values

    /// For a transaction that was canceled by Apple customer support, the time and date of the cancellation. For an auto-renewable subscription plan that was upgraded, the time and date of the upgrade transaction.
    let cancellationDate: Date?

    /// For a transaction that was canceled by Apple customer support, the time and date of the cancellation. For an auto-renewable subscription plan that was upgraded, the time and date of the upgrade transaction.
    let cancellationReason: Int? // TODO: create an enum for int values
    
    /// A string that the App Store uses to uniquely identify the application that created the transaction.
    let appItemId: String?
    
    /// This key is not present for receipts created in the test environment. Use this value to identify the version of the app that the customer bought.
    let externalVersionIdentifier: String?
    
    /// For a subscription, whether or not it is in the free trial period.
    let isTrialPeriod: Bool?
    /// For an auto-renewable subscription, whether or not it is in the introductory price period.
    let isInIntroOfferPeriod: Bool?

    /// The primary key for identifying subscription purchases.
    let webOrderLineItemId: String?
    
    /// The current renewal status for the auto-renewable subscription.
    let subscriptionAutoRenewStatus: Int? // TODO: create an enum for int values
    
    /// The current renewal preference for the auto-renewable subscription.
    let subscriptionAutoRenewPreference: String?
    
    /// The current price consent status for a subscription price increase.
    let subscriptionPriceConsentStatus: Int? // TODO: create an enum for int values

    
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
    
    // MARK: - Lifecycle
    
    init?(quantity: Int?,
          productIdentifier: String?,
          transactionIdentifier: String?,
          originalTransactionIdentifier: String?,
          purchaseDate: Date?,
          originalPurchaseDate: Date?,
          subscriptionExpirationDate: Date?,
          subscriptionIntroductoryPricePeriod: Bool?,
          cancellationDate: Date?,
          webOrderLineItemId: String?) {
        guard let quantity = quantity,
            let productIdentifier = productIdentifier,
            let transactionIdentifier = transactionIdentifier else {
                return nil
        }
        
        self.quantity = quantity
        self.productId = productIdentifier
        self.transactionId = transactionIdentifier
        self.originalTransactionId = originalTransactionIdentifier
        
        self.purchaseDate = purchaseDate
        self.purchaseDateMs = purchaseDate
        self.purchaseDatePst = purchaseDate
        
        self.originalPurchaseDate = originalPurchaseDate
        self.originalPurchaseDateMs = originalPurchaseDate
        self.originalPurchaseDatePst = originalPurchaseDate

        self.expiresDate = subscriptionExpirationDate
        self.expiresDateMs = subscriptionExpirationDate
        self.expiresDatePst = subscriptionExpirationDate

        self.isInIntroOfferPeriod = subscriptionIntroductoryPricePeriod
        self.cancellationDate = cancellationDate
        self.webOrderLineItemId = webOrderLineItemId
        
        self.subscriptionExpirationIntent = nil
        self.subscriptionRetryFlag = nil
        self.cancellationReason = nil
        self.appItemId = nil
        self.externalVersionIdentifier = nil
        self.isTrialPeriod = nil
        self.subscriptionAutoRenewStatus = nil
        self.subscriptionAutoRenewPreference = nil
        self.subscriptionPriceConsentStatus = nil
    }
}

// MARK: - Codable
extension InAppPurchase: Codable {
    enum CodingKeys: String, CodingKey {
        case quantity
        case productId = "product_id"
        case transactionId = "transaction_id"
        case originalTransactionId = "original_transaction_id"
        case purchaseDate = "purchase_date"
        case purchaseDateMs = "purchase_date_ms"
        case purchaseDatePst = "purchase_date_pst"
        case originalPurchaseDate = "original_purchase_date"
        case originalPurchaseDateMs = "original_purchase_date_ms"
        case originalPurchaseDatePst = "original_purchase_date_pst"
        case expiresDate = "expires_date"
        case expiresDateMs = "expires_date_ms"
        case expiresDatePst = "expires_date_pst"
        
        case subscriptionExpirationIntent = "expiration_intent"
        case subscriptionRetryFlag = "is_in_billing_retry_period"
        case cancellationDate = "cancellation_date"
        case cancellationReason = "cancellation_reason"
        case appItemId = "app_item_id"
        case externalVersionIdentifier = "version_external_identifier"
        
        case isTrialPeriod = "is_trial_period"
        case isInIntroOfferPeriod = "is_in_intro_offer_period"
        
        case webOrderLineItemId = "web_order_line_item_id"
        
        case subscriptionAutoRenewStatus = "auto_renew_status"
        case subscriptionAutoRenewPreference = "auto_renew_product_id"
        case subscriptionPriceConsentStatus = "price_consent_status"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        quantity = Int(try values.decode(String.self, forKey: .quantity)) ?? 0
        productId = try values.decode(String.self, forKey: .productId)
        transactionId = try values.decode(String.self, forKey: .transactionId)
        originalTransactionId = try values.decode(String.self, forKey: .originalTransactionId)
        
        purchaseDate = try values.decodeIfPresent(Date.self, forKey: .purchaseDate)
        purchaseDatePst = try values.decodeIfPresent(Date.self, forKey: .purchaseDatePst)
        purchaseDateMs = try values.decodeIfPresent(Date.self, forKey: .purchaseDateMs)
        
        originalPurchaseDate = try values.decodeIfPresent(Date.self, forKey: .originalPurchaseDate)
        originalPurchaseDatePst = try values.decodeIfPresent(Date.self, forKey: .originalPurchaseDatePst)
        originalPurchaseDateMs = try values.decodeIfPresent(Date.self, forKey: .originalPurchaseDateMs)
        
        expiresDate = try values.decodeIfPresent(Date.self, forKey: .expiresDate)
        expiresDatePst = try values.decodeIfPresent(Date.self, forKey: .expiresDatePst)
        expiresDateMs = try values.decodeIfPresent(Date.self, forKey: .expiresDateMs)
        
        if let subscriptionExpirationIntentStr = try values.decodeIfPresent(String.self, forKey: .subscriptionExpirationIntent) {
            subscriptionExpirationIntent = Int(subscriptionExpirationIntentStr)
        } else {
            subscriptionExpirationIntent = nil
        }
        
        if let subscriptionRetryFlagStr = try values.decodeIfPresent(String.self, forKey: .subscriptionRetryFlag) {
            subscriptionRetryFlag = Int(subscriptionRetryFlagStr)
        } else {
            subscriptionRetryFlag = nil
        }
        
        if let cancellationDateStr = try values.decodeIfPresent(String.self, forKey: .cancellationDate) {
            cancellationDate = DateFormatter.appleValidator.date(from: cancellationDateStr)
        } else {
            cancellationDate = nil
        }
        if let cancellationReasonStr = try values.decodeIfPresent(String.self, forKey: .cancellationReason) {
            cancellationReason = Int(cancellationReasonStr)
        } else {
            cancellationReason = nil
        }
        
        appItemId = try values.decodeIfPresent(String.self, forKey: .appItemId)
        externalVersionIdentifier = try values.decodeIfPresent(String.self, forKey: .externalVersionIdentifier)
        
        if let isTrialPeriodString = try values.decodeIfPresent(String.self, forKey: .isTrialPeriod) {
            isTrialPeriod = Bool(isTrialPeriodString)
        } else{
            isTrialPeriod = nil
        }
        if let isInIntroOfferPeriodString = try values.decodeIfPresent(String.self, forKey: .isInIntroOfferPeriod) {
            isInIntroOfferPeriod = Bool(isInIntroOfferPeriodString)
        } else {
            isInIntroOfferPeriod = nil
        }
        webOrderLineItemId = try values.decodeIfPresent(String.self, forKey: .webOrderLineItemId)
        
        if let subscriptionAutoRenewStatusStr = try values.decodeIfPresent(String.self, forKey: .subscriptionAutoRenewStatus) {
            subscriptionAutoRenewStatus = Int(subscriptionAutoRenewStatusStr)
        } else {
            subscriptionAutoRenewStatus = nil
        }
        
        subscriptionAutoRenewPreference = try values.decodeIfPresent(String.self, forKey: .subscriptionAutoRenewPreference)
        
        if let subscriptionPriceConsentStatusStr = try values.decodeIfPresent(String.self, forKey: .subscriptionPriceConsentStatus) {
            subscriptionPriceConsentStatus = Int(subscriptionPriceConsentStatusStr)
        } else {
            subscriptionPriceConsentStatus = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(quantity, forKey: .quantity)
        try container.encode(productId, forKey: .productId)
        try container.encode(transactionId, forKey: .transactionId)
        try container.encode(originalTransactionId, forKey: .originalTransactionId)
        
        try container.encode(purchaseDate, forKey: .purchaseDate)
        try container.encode(purchaseDatePst, forKey: .purchaseDatePst)
        try container.encode(purchaseDateMs?.timeIntervalSince1970, forKey: .purchaseDateMs)

        try container.encode(originalPurchaseDate, forKey: .originalPurchaseDate)
        try container.encode(originalPurchaseDatePst, forKey: .originalPurchaseDatePst)
        try container.encode(originalPurchaseDateMs?.timeIntervalSince1970, forKey: .originalPurchaseDateMs)

        try container.encode(expiresDate, forKey: .expiresDate)
        try container.encode(expiresDatePst, forKey: .expiresDatePst)
        try container.encode(expiresDateMs?.timeIntervalSince1970, forKey: .expiresDateMs)

        try container.encode(subscriptionExpirationIntent, forKey: .subscriptionExpirationIntent)
        try container.encode(subscriptionRetryFlag, forKey: .subscriptionRetryFlag)
        try container.encode(cancellationDate, forKey: .cancellationDate)
        try container.encode(cancellationReason, forKey: .cancellationReason)

        try container.encode(appItemId, forKey: .appItemId)
        try container.encode(externalVersionIdentifier, forKey: .externalVersionIdentifier)
        try container.encode(isTrialPeriod, forKey: .isTrialPeriod)
        try container.encode(isInIntroOfferPeriod, forKey: .isInIntroOfferPeriod)
        
        try container.encode(webOrderLineItemId, forKey: .webOrderLineItemId)
        try container.encode(subscriptionAutoRenewStatus, forKey: .subscriptionAutoRenewStatus)
        try container.encode(subscriptionAutoRenewPreference, forKey: .subscriptionAutoRenewPreference)
        try container.encode(subscriptionPriceConsentStatus, forKey: .subscriptionPriceConsentStatus)
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
