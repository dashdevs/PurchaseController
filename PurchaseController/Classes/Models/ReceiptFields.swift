//
//  ReceiptFields.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

/// Represents IAP receipt fields related to app receipt for ASN.1 and JSON.
///
/// # See also
/// [App Receipt Fields](https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html)
struct AppReceiptFields {
    private typealias CodingKeys = Receipt.CodingKeys
    
    /// The app’s bundle identifier.
    ///
    /// This corresponds to the value of CFBundleIdentifier in the Info.plist file. Use this value to validate if the receipt was indeed generated for your app.
    static let bundleIdentifier = ReceiptField(asn1Type: 2, jsonKey: CodingKeys.bundleId.rawValue)
    
    /// The app’s version number.
    ///
    /// This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in the Info.plist.
    static let appVersion = ReceiptField(asn1Type: 3, jsonKey: CodingKeys.applicationVersion.rawValue)
    
    /// An opaque value used, with other data, to compute the SHA-1 hash during validation.
    static let opaqueValue = ReceiptField(asn1Type: 4, jsonKey: nil)
    
    /// A SHA-1 hash, used to validate the receipt.
    static let sha1Hash = ReceiptField(asn1Type: 5, jsonKey: nil)
    
    /// The receipt for an in-app purchase.
    ///
    /// In the JSON file, the value of this key is an array containing all in-app purchase receipts based on the in-app purchase transactions present in the input base-64 receipt-data.
    /// For receipts containing auto-renewable subscriptions, check the value of the latest_receipt_info key to get the status of the most recent renewal.
    ///
    /// In the ASN.1 file, there are multiple fields that all have type 17, each of which contains a single in-app purchase receipt.
    ///
    /// Note: An empty array is a valid receipt.
    /// The in-app purchase receipt for a consumable product is added to the receipt when the purchase is made. It is kept in the receipt until your app finishes that transaction.
    /// After that point, it is removed from the receipt the next time the receipt is updated - for example, when the user makes another purchase or if your app explicitly refreshes the receipt.
    static let inAppPurchaseReceipt = ReceiptField(asn1Type: 17, jsonKey: CodingKeys.inApp.rawValue)
    
    /// The version of the app that was originally purchased.
    ///
    /// This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in the Info.plist file when the purchase was originally made.
    ///
    /// In the sandbox environment, the value of this field is always “1.0”.
    static let originalApplicationVersion = ReceiptField(asn1Type: 19, jsonKey: CodingKeys.originalApplicationVersion.rawValue)
    
    /// The date when the app receipt was created.
    ///
    /// When validating a receipt, use this date to validate the receipt’s signature.
    ///
    /// Note: Many cryptographic libraries default to using the device’s current time and date when validating a PKCS7 package, but this may not produce the correct results when validating a receipt’s signature.
    /// For example, if the receipt was signed with a valid certificate, but the certificate has since expired, using the device’s current date incorrectly returns an invalid result.
    ///
    /// Therefore, make sure your app always uses the date from the Receipt Creation Date field to validate the receipt’s signature.
    static let receiptCreationDate = ReceiptField(asn1Type: 12, jsonKey: CodingKeys.receiptCreationDate.rawValue)
    
    /// The date that the app receipt expires.
    ///
    /// This key is present only for apps purchased through the Volume Purchase Program. If this key is not present, the receipt does not expire.
    ///
    /// When validating a receipt, compare this date to the current date to determine whether the receipt is expired. Do not try to use this date to calculate any other information, such as the time remaining before expiration.
    static let receiptExpirationDate = ReceiptField(asn1Type: 21, jsonKey: CodingKeys.receiptExpirationDate.rawValue)
}

/// Represents IAP receipt fields related to purchase for ASN.1 and JSON.
///
/// # See also
/// [In-App Purchase Receipt Fields](https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html)
struct PurchaseReceiptFields {
    
    private typealias CodingKeys = InAppPurchase.CodingKeys
    
    /// The number of items purchased.
    ///
    /// This value corresponds to the quantity property of the SKPayment object stored in the transaction’s payment property.
    static let quantity = ReceiptField(asn1Type: 1701, jsonKey: CodingKeys.quantity.rawValue)
    
    /// The number of items purchased.
    ///
    /// This value corresponds to the productIdentifier property of the SKPayment object stored in the transaction’s payment property.
    static let productIdentifier = ReceiptField(asn1Type: 1702, jsonKey: CodingKeys.productId.rawValue)
    
    /// The transaction identifier of the item that was purchased.
    ///
    /// This value corresponds to the transaction’s transactionIdentifier property.
    static let transactionIdentifier = ReceiptField(asn1Type: 1703, jsonKey: CodingKeys.transactionId.rawValue)
    
    /// For a transaction that restores a previous transaction, the transaction identifier of the original transaction. Otherwise, identical to the transaction identifier.
    ///
    /// This value corresponds to the original transaction’s transactionIdentifier property.
    static let originalTransactionIdentifier = ReceiptField(asn1Type: 1705, jsonKey: CodingKeys.originalTransactionId.rawValue)
    
    /// The date and time that the item was purchased.
    ///
    /// This value corresponds to the transaction’s transactionDate property.
    static let purchaseDate = ReceiptField(asn1Type: 1704, jsonKey: CodingKeys.purchaseDate.rawValue)
    
    /// For a transaction that restores a previous transaction, the date of the original transaction.
    ///
    /// This value corresponds to the original transaction’s transactionDate property.
    static let originalPurchaseDate = ReceiptField(asn1Type: 1706, jsonKey: CodingKeys.originalPurchaseDate.rawValue)
    
    /// The expiration date for the subscription, expressed as the number of milliseconds since January 1, 1970, 00:00:00 GMT.
    ///
    /// This key is only present for auto-renewable subscription receipts. Use this value to identify the date when the subscription will renew or expire,
    /// to determine if a customer should have access to content or service. After validating the latest receipt,
    /// if the subscription expiration date for the latest renewal transaction is a past date, it is safe to assume that the subscription has expired.
    static let subscriptionExpirationDate = ReceiptField(asn1Type: 1708, jsonKey: CodingKeys.expiresDate.rawValue)
    
    /// For an expired subscription, the reason for the subscription expiration.
    ///
    /// This key is only present for a receipt containing an expired auto-renewable subscription. You can use this value to decide whether to display appropriate messaging in your app for customers to resubscribe.
    static let subscriptionExpirationIntent = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.subscriptionExpirationIntent.rawValue)
    
    /// For an expired subscription, whether or not Apple is still attempting to automatically renew the subscription.
    ///
    /// This key is only present for auto-renewable subscription receipts. If the customer’s subscription failed to renew because the App Store was unable to complete the transaction,
    /// this value will reflect whether or not the App Store is still trying to renew the subscription.
    static let subscriptionRetryFlag = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.subscriptionRetryFlag.rawValue)
    
    /// For a subscription, whether or not it is in the free trial period.
    ///
    /// This key is only present for auto-renewable subscription receipts. The value for this key is "true" if the customer’s subscription is currently in the free trial period, or "false" if not.
    static let subscriptionTrialPeriod = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.isTrialPeriod.rawValue)
    
    /// For an auto-renewable subscription, whether or not it is in the introductory price period.
    ///
    /// This key is only present for auto-renewable subscription receipts. The value for this key is "true" if the customer’s subscription is currently in an introductory price period, or "false" if not.
    static let subscriptionIntroductoryPricePeriod = ReceiptField(asn1Type: 1719, jsonKey: CodingKeys.isInIntroOfferPeriod.rawValue)
    
    /// For a transaction that was canceled by Apple customer support, the time and date of the cancellation. For an auto-renewable subscription plan that was upgraded, the time and date of the upgrade transaction.
    ///
    /// Treat a canceled receipt the same as if no purchase had ever been made.
    static let cancellationDate = ReceiptField(asn1Type: 1712, jsonKey: CodingKeys.cancellationDate.rawValue)
    
    /// For a transaction that was canceled, the reason for cancellation.
    ///
    /// Use this value along with the cancellation date to identify possible issues in your app that may lead customers to contact Apple customer support.
    static let cancellationReason = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.cancellationReason.rawValue)
    
    /// A string that the App Store uses to uniquely identify the application that created the transaction.
    ///
    /// If your server supports multiple applications, you can use this value to differentiate between them.
    /// Apps are assigned an identifier only in the production environment, so this key is not present for receipts created in the test environment.
    static let appItemId = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.appItemId.rawValue)
    
    /// An arbitrary number that uniquely identifies a revision of your application.
    ///
    /// This key is not present for receipts created in the test environment. Use this value to identify the version of the app that the customer bought.
    static let externalVersionIdentifier = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.externalVersionIdentifier.rawValue)
    
    /// The primary key for identifying subscription purchases.
    ///
    /// This value is a unique ID that identifies purchase events across devices, including subscription renewal purchase events.
    static let webOrderLineItemId = ReceiptField(asn1Type: 1711, jsonKey: CodingKeys.webOrderLineItemId.rawValue)
    
    /// The current renewal status for the auto-renewable subscription.
    ///
    /// This key is only present for auto-renewable subscription receipts, for active or expired subscriptions. The value for this key should not be interpreted as the customer’s subscription status.
    /// You can use this value to display an alternative subscription product in your app, for example, a lower level subscription plan that the customer can downgrade to from their current plan.
    static let subscriptionAutoRenewStatus = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.subscriptionAutoRenewStatus.rawValue)
    
    /// The current renewal preference for the auto-renewable subscription.
    ///
    /// This key is only present for auto-renewable subscription receipts. The value for this key corresponds to the productIdentifier property of the product that the customer’s subscription renews.
    /// You can use this value to present an alternative service level to the customer before the current subscription period ends.
    static let subscriptionAutoRenewPreference = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.subscriptionAutoRenewPreference.rawValue)
    
    /// The current price consent status for a subscription price increase.
    ///
    /// This key is only present for auto-renewable subscription receipts if the subscription price was increased without keeping the existing price for active subscribers.
    /// You can use this value to track customer adoption of the new price and take appropriate action.
    static let subscriptionPriceConsentStatus = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.subscriptionPriceConsentStatus.rawValue)
}

struct ReceiptField {
    
    let asn1Type: Int?
    let jsonKey: String?
    
    init(asn1Type: Int?, jsonKey: String?) {
        self.asn1Type = asn1Type
        self.jsonKey = jsonKey
    }
}

/// For an expired subscription, the reason for the subscription expiration.
///
/// - customerCanceledSubscription: Customer canceled their subscription.
/// - billingError: Billing error; for example customer’s payment information was no longer valid.
/// - customerDidNotAgreeToPriceIncrease: Customer did not agree to a recent price increase.
/// - productWasNotAvailable: Product was not available for purchase at the time of renewal.
/// - unknownError: Unknown error.
public enum SubscriptionExpirationIntent: String, Codable {
    case customerCanceledSubscription = "1"
    case billingError = "2"
    case customerDidNotAgreeToPriceIncrease = "3"
    case productWasNotAvailable = "4"
    case unknownError = "5"
}

/// For an expired subscription, whether or not Apple is still attempting to automatically renew the subscription.
///
/// - stillAttempting: App Store is still attempting to renew the subscription.
/// - stoppedAttempting: App Store has stopped attempting to renew the subscription.
public enum SubscriptionRetryFlag: String, Codable {
    case stillAttempting = "1"
    case stoppedAttempting = "0"
}

/// For a transaction that was canceled, the reason for cancellation.
///
/// - customerCanceled: Customer canceled their transaction due to an actual or perceived issue within your app.
/// - anotherReason: Transaction was canceled for another reason, for example, if the customer made the purchase accidentally.
public enum CancellationReason: String, Codable {
    case customerCanceled = "1"
    case anotherReason = "0"
}

/// The current renewal status for the auto-renewable subscription.
///
/// - willRenew: Subscription will renew at the end of the current subscription period.
/// - autoRenewalTurnedOff: Customer has turned off automatic renewal for their subscription.
public enum SubscriptionAutoRenewStatus: String, Codable {
    case willRenew = "1"
    case autoRenewalTurnedOff = "0"
}

/// The current price consent status for a subscription price increase.
///
/// - agreed: Customer has agreed to the price increase. Subscription will renew at the higher price.
/// - notTakenAction: Customer has not taken action regarding the increased price. Subscription expires if the customer takes no action before the renewal.
public enum SubscriptionPriceConsentStatus: String, Codable {
    case agreed = "1"
    case notTakenAction = "0"
}
