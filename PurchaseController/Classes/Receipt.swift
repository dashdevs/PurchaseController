//
//  Receipt.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

struct Receipt: Codable {
    
    //this is optional and maybe this need to skip
    let receiptCreationDate: String
    let receiptCreationDatePst: String
    let originalPurchaseDate: String
    let originalPurchaseDatePst: String
    let requestDate: String
    let requestDatePst: String
    let receiptType: String
    let appItemId: Int
    let receiptCreationDateMs: Date?
    let bundleId: String
    let originalPurchaseDateMs: Date?
    let adamId: Int
    let versionExternalIdentifier: Int
    let requestDateMs: Date?
    let applicationVersion: String
    let originalApplicationVersion: String
    let downloadId: Int
    let inApp: [InApp]
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        //this is optional and maybe this need to skip
        receiptCreationDate = try values.decode(String.self, forKey: .receiptCreationDate)
        receiptCreationDatePst = try values.decode(String.self, forKey: .receiptCreationDatePst)
        requestDatePst = try values.decode(String.self, forKey: .requestDatePst)
        originalPurchaseDatePst = try values.decode(String.self, forKey: .originalPurchaseDatePst)
        originalPurchaseDate = try values.decode(String.self, forKey: .originalPurchaseDate)
        receiptType = try values.decode(String.self, forKey: .receiptType)
        appItemId = try values.decode(Int.self, forKey: .appItemId)
        bundleId = try values.decode(String.self, forKey: .bundleId)
        if let creationDateString = try? values.decode(String.self, forKey: .receiptCreationDateMs) {
            receiptCreationDateMs = creationDateString.date()
        } else {
            receiptCreationDateMs = nil
        }
        if let purchaseDateString = try? values.decode(String.self, forKey: .originalPurchaseDateMs) {
            originalPurchaseDateMs = purchaseDateString.date()
        } else {
            originalPurchaseDateMs = nil
        }
        adamId = try values.decode(Int.self, forKey: .adamId)
        requestDate = try values.decode(String.self, forKey: .requestDate)
        versionExternalIdentifier = try values.decode(Int.self, forKey: .versionExternalIdentifier)
        if let requestDateString = try? values.decode(String.self, forKey: .requestDateMs) {
            requestDateMs = requestDateString.date()
        } else {
            requestDateMs = nil
        }
        applicationVersion = try values.decode(String.self, forKey: .applicationVersion)
        originalApplicationVersion = try values.decode(String.self, forKey: .originalApplicationVersion)
        downloadId = try values.decode(Int.self, forKey: .downloadId)
        inApp = try values.decode([InApp].self, forKey: .inApp)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(receiptCreationDate, forKey: .receiptCreationDate)
        try container.encode(receiptCreationDatePst, forKey: .receiptCreationDatePst)
        try container.encode(requestDatePst, forKey: .requestDatePst)
        try container.encode(originalPurchaseDatePst, forKey: .originalPurchaseDatePst)
        try container.encode(originalPurchaseDate, forKey: .originalPurchaseDate)
        try container.encode(receiptType, forKey: .receiptType)
        try container.encode(appItemId, forKey: .appItemId)
        try container.encode(bundleId, forKey: .bundleId)
        try container.encode(receiptCreationDateMs, forKey: .receiptCreationDateMs)
        try container.encode(originalPurchaseDateMs, forKey: .originalPurchaseDateMs)
        try container.encode(adamId, forKey: .adamId)
        try container.encode(requestDate, forKey: .requestDate)
        try container.encode(applicationVersion, forKey: .applicationVersion)
        try container.encode(originalApplicationVersion, forKey: .originalApplicationVersion)
        try container.encode(downloadId, forKey: .downloadId)
        try container.encode(appItemId, forKey: .appItemId)
        try container.encode(inApp, forKey: .inApp)
        try container.encode(originalPurchaseDateMs, forKey: .originalPurchaseDateMs)
        try container.encode(adamId, forKey: .adamId)
    }
    
    enum CodingKeys: String, CodingKey {
        //this is optional and maybe this need to skip
        case receiptCreationDate = "receipt_creation_date"
        case receiptCreationDatePst = "receipt_creation_date_pst"
        case originalPurchaseDate = "original_purchase_date"
        case originalPurchaseDatePst = "original_purchase_date_pst"
        case requestDate = "request_date"
        case requestDatePst = "request_date_pst"
        case receiptType = "receipt_type"
        case appItemId = "app_item_id"
        case receiptCreationDateMs = "receipt_creation_date_ms"
        case bundleId = "bundle_id"
        case originalPurchaseDateMs = "original_purchase_date_ms"
        case adamId = "adam_id"
        case versionExternalIdentifier = "version_external_identifier"
        case requestDateMs = "request_date_ms"
        case applicationVersion = "application_version"
        case originalApplicationVersion = "original_application_version"
        case downloadId = "download_id"
        case inApp = "in_app"
    }
    
}
