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
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        status = try values.decode(Int.self, forKey: .status)
        environment = try values.decode(String.self, forKey: .environment)
        receipt = try values.decode(Receipt.self, forKey: .receipt)
        latestReceiptInfo = try? values.decode([InApp].self, forKey: .latestReceiptInfo)
        latestReceipt = try? values.decode(String.self, forKey: .latestReceipt)
        pendingRenewalInfo = try? values.decode([PendingRenewalInfo].self, forKey: .pendingRenewalInfo)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(status, forKey: .status)
        try container.encode(environment, forKey: .environment)
        try container.encode(receipt, forKey: .receipt)
        try container.encode(latestReceiptInfo, forKey: .latestReceiptInfo)
        try container.encode(latestReceipt, forKey: .latestReceipt)
        try container.encode(pendingRenewalInfo, forKey: .pendingRenewalInfo)
    }
}



