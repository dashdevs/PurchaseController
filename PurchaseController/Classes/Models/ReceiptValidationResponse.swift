//
//  ReceiptValidationResponse.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

/// Environment of receipt
///
/// - production: https://buy.itunes.apple.com/verifyReceipt
/// - sandbox: https://sandbox.itunes.apple.com/verifyReceipt
enum EnvironmentType: String, Codable {
    case production = "Production"
    case sandbox = "Sandbox"
}

/// The response’s payload
public struct ReceiptValidationResponse: Codable {
    /// Either 0 if the receipt is valid, or one of the error codes listed in https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html#//apple_ref/doc/uid/TP40010573-CH104-SW5
    let status: Int
    /// Environment of receipt, listed in EnvironmentType
    let environment: EnvironmentType
    /// Object that describes receipt item
    let receipt: Receipt?
    /// Array of Latests Receipt
    let latestReceiptInfo: [InAppPurchase]?
    /// Latest Receipt - the status of the most recent renewal
    let latestReceipt: String?
    /// Pending Renewal Info - array of pending renewal info
    let pendingRenewalInfo: [PendingRenewalInfo]?
    
    enum CodingKeys: String, CodingKey {
        case status
        case receipt
        case latestReceiptInfo = "latest_receipt_info"
        case latestReceipt = "latest_receipt"
        case pendingRenewalInfo = "pending_renewal_info"
        case environment
    }
}

// Error when managing receipt
public enum ReceiptError: Swift.Error {
    // No receipt data
    case noReceiptData
    // No data received
    case noRemoteData
    // Error when encoding HTTP body into JSON
    case requestBodyEncodeError(error: Swift.Error)
    // Error when proceeding request
    case networkError(error: Swift.Error)
    // Error when decoding response
    case jsonDecodeError(string: String?)
    // Receive invalid - bad status returned
    case receiptInvalid(receipt: ReceiptValidationResponse, status: ReceiptStatus)
}

// Status code returned by remote server
// see Table 2-1  Status codes
public enum ReceiptStatus: Int {
    // Not decodable status
    case unknown = -2
    // No status returned
    case none = -1
    // valid statu
    case valid = 0
    // The App Store could not read the JSON object you provided.
    case jsonNotReadable = 21000
    // The data in the receipt-data property was malformed or missing.
    case malformedOrMissingData = 21002
    // The receipt could not be authenticated.
    case receiptCouldNotBeAuthenticated = 21003
    // The shared secret you provided does not match the shared secret on file for your account.
    case secretNotMatching = 21004
    // The receipt server is not currently available.
    case receiptServerUnavailable = 21005
    // This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response.
    case subscriptionExpired = 21006
    //  This receipt is from the test environment, but it was sent to the production environment for verification. Send it to the test environment instead.
    case testReceipt = 21007
    // This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead.
    case productionEnvironment = 21008
}
