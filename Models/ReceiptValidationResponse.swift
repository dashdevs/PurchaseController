//
//  ReceiptValidationResponse.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

struct ReceiptValidationResponse: Codable {
    
    let status: Int
    let environment: String
    let receipt: Receipt?
    let latestReceiptInfo: [InApp]?
    let latestReceipt: String?
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



