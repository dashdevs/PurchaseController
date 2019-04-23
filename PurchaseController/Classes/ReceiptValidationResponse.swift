//
//  ReceiptValidationResponse.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

enum EnvironmentType: String, Codable {
    case production
    case sandbox
}

public struct ReceiptValidationResponse: Codable {
    ///
    let status: Int
    
    let environment: String
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
