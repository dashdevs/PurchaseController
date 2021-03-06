//
//  Receipt.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

enum ReceiptType: String, Codable {
    case sandbox = "Sandbox"
    case production = "Production"
    case productionSandbox = "ProductionSandbox"
}

public struct Receipt: ReadableDebugStringProtocol, DataFormatsEncodable {
    
    // MARK: - Properties
    
    /// Bundle Identifier - The app’s bundle identifier.
    let bundleId: String
    
    /// App Version - The app’s version number.
    let applicationVersion: String

    ///In-App Purchase Receipt - The receipt for an in-app purchase. Note: An empty array is a valid receipt.
    let inApp: [InAppPurchase]?

    /// Original Application Version - The version of the app that was originally purchased.
    ///
    /// In the sandbox environment, the value of this field is always “1.0”.
    let originalApplicationVersion: String

    /// Receipt Creation Date - The date when the app receipt was created.
    ///
    /// When validating a receipt, use this date to validate the receipt’s signature.
    let receiptCreationDate: Date?
    let receiptCreationDatePst: Date?
    let receiptCreationDateMs: TimeInterval?
    
    /// The date that the app receipt expires.
    let receiptExpirationDate: Date?
    
    /// Original Purchase Date - For a transaction that restores a previous transaction, the date of the original transaction.
    let originalPurchaseDate: Date?
    let originalPurchaseDatePst: Date?
    let originalPurchaseDateMs: TimeInterval?
    
    let requestDate: Date?
    let requestDatePst: Date?
    let requestDateMs: TimeInterval?
    
    let receiptType: ReceiptType?
    /// App Item ID - A string that the App Store uses to uniquely identify the application that created the transaction.
    let appItemId: Int?
    
    let adamId: Int?
    
    /// External Version Identifier - An arbitrary number that uniquely identifies a revision of your application.
    let versionExternalIdentifier: Int?
    
    let downloadId: Int?
    
    // MARK: - Lifecycle
    
    init?(bundleIdentifier: String?,
          appVersion: String?,
          originalAppVersion: String?,
          inAppPurchaseReceipts: [InAppPurchase],
          receiptCreationDate: Date?,
          expirationDate: Date?) {
        guard let bundleIdentifier = bundleIdentifier,
            let appVersion = appVersion,
            let originalAppVersion = originalAppVersion,
            let receiptCreationDate = receiptCreationDate else {
                return nil
        }
        
        self.bundleId = bundleIdentifier
        self.applicationVersion = appVersion
        self.inApp = inAppPurchaseReceipts
        self.originalApplicationVersion = originalAppVersion
        self.receiptCreationDate = receiptCreationDate
        self.receiptCreationDatePst = receiptCreationDate
        self.receiptCreationDateMs = nil
        self.receiptExpirationDate = expirationDate
        self.originalPurchaseDate = nil
        self.originalPurchaseDatePst = nil
        self.originalPurchaseDateMs = nil
        self.requestDate = nil
        self.requestDatePst = nil
        self.requestDateMs = nil
        self.appItemId = nil
        self.adamId = nil
        self.versionExternalIdentifier = nil
        self.downloadId = nil
        self.receiptType = nil
    }
}

// MARK: - Codable
extension Receipt: Codable {
    
    enum CodingKeys: String, CodingKey {
        case bundleId = "bundle_id"
        case applicationVersion = "application_version"
        case inApp = "in_app"
        case originalApplicationVersion = "original_application_version"
        case receiptCreationDate = "receipt_creation_date"
        case receiptCreationDatePst = "receipt_creation_date_pst"
        case receiptCreationDateMs = "receipt_creation_date_ms"
        case receiptExpirationDate = "expiration_date"
        case originalPurchaseDate = "original_purchase_date"
        case originalPurchaseDatePst = "original_purchase_date_pst"
        case originalPurchaseDateMs = "original_purchase_date_ms"
        case requestDate = "request_date"
        case requestDatePst = "request_date_pst"
        case requestDateMs = "request_date_ms"
        case receiptType = "receipt_type"
        case appItemId = "app_item_id"
        case adamId = "adam_id"
        case versionExternalIdentifier = "version_external_identifier"
        case downloadId = "download_id"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        bundleId = try values.decode(String.self, forKey: .bundleId)
        applicationVersion = try values.decode(String.self, forKey: .applicationVersion)
        inApp = try? values.decode([InAppPurchase].self, forKey: .inApp)
        originalApplicationVersion = try values.decode(String.self, forKey: .originalApplicationVersion)
        
        receiptCreationDate = try values.decodeIfPresent(Date.self, forKey: .receiptCreationDate)
        receiptCreationDatePst = try values.decodeIfPresent(Date.self, forKey: .receiptCreationDatePst)
        receiptCreationDateMs = {
            guard let str = try? values.decode(String.self, forKey: .receiptCreationDateMs) else { return nil }
            return TimeInterval(millisecondsString: str)
        }()
        
        receiptExpirationDate = try values.decodeIfPresent(Date.self, forKey: .receiptExpirationDate)
        
        originalPurchaseDate = try values.decodeIfPresent(Date.self, forKey: .originalPurchaseDate)
        originalPurchaseDatePst = try values.decodeIfPresent(Date.self, forKey: .originalPurchaseDatePst)

        originalPurchaseDateMs = {
            guard let str = try? values.decode(String.self, forKey: .originalPurchaseDateMs) else { return nil }
            return TimeInterval(millisecondsString: str)
        }()

        requestDate = try values.decodeIfPresent(Date.self, forKey: .requestDate)
        requestDatePst = try values.decodeIfPresent(Date.self, forKey: .requestDatePst)
        requestDateMs = {
            guard let str = try? values.decode(String.self, forKey: .requestDateMs) else { return nil }
            return TimeInterval(millisecondsString: str)
        }()
        
        receiptType = try values.decodeIfPresent(ReceiptType.self, forKey: .receiptType)
        appItemId = try values.decode(Int.self, forKey: .appItemId)
        adamId = try values.decode(Int.self, forKey: .adamId)
        versionExternalIdentifier = try values.decode(Int.self, forKey: .versionExternalIdentifier)
        downloadId = try values.decode(Int.self, forKey: .downloadId)
    }
}
