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
    let latestReceiptInfo: [InApp]?
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
