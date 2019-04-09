//
//  Receipt.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

struct Receipt: Codable {
    
    let receiptCreationDate: Date?
    let receiptCreationDatePst:  Date?
    let originalPurchaseDate: Date?
    let originalPurchaseDatePst: Date?
    let requestDate: Date?
    let requestDatePst: Date?
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
    let dateTimeZone: TimeZone?
    let pstDateTimeZone: TimeZone?
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let originalPurchaseDateStr = try? values.decode(String.self, forKey: .originalPurchaseDate) {
            let strs = originalPurchaseDateStr.components(separatedBy:" ")
            dateTimeZone = TimeZone(identifier: strs[strs.count - 1]) ?? nil
        } else {
            dateTimeZone = nil
        }
        
        if let originalPurchaseDateStr = try? values.decode(String.self, forKey: .originalPurchaseDatePst) {
            let strs = originalPurchaseDateStr.components(separatedBy:" ")
            pstDateTimeZone = TimeZone(identifier: strs[strs.count - 1]) ?? nil
        } else {
            pstDateTimeZone = nil
        }
        
        receiptCreationDate = Date()//try values.decode(String.self, forKey: .receiptCreationDate)
        receiptCreationDatePst = Date() //try values.decode(String.self, forKey: .receiptCreationDatePst)
        originalPurchaseDatePst =  Date()//try values.decode(String.self, forKey: .originalPurchaseDatePst)
        originalPurchaseDate =  Date()// try values.decode(String.self, forKey: .originalPurchaseDate)
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
        let dateFormatter = DateFormatter(dateFormat: .datePst)
        if let requestDateString = try? values.decode(String.self, forKey: .requestDate) {
            requestDate = dateFormatter.date(from: requestDateString)
        } else {
            requestDate = nil
        }
        if let requestDatePstString = try? values.decode(String.self, forKey: .requestDatePst) {
            requestDatePst = dateFormatter.date(from: requestDatePstString)
        } else {
            requestDatePst = nil
        }
        
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
    
    enum CodingKeys: String, CodingKey {
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
