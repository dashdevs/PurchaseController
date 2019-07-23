//
//  SectionTableItemModel.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

enum SectionTableItemModel: String {
    
    case purchases = "Purchases"
    case action = "Actions"
    
    private var purchaseSection: [TableItemModel] { return [.consumable, .nonConsumable, .autoRenewSubscription, .nonRenewSubscription] }
    private var actionSection: [TableItemModel] { return [.retrieve, .restore, .validateReceiptLocally, .validateReceiptRemotely, .refreshReceipt, .validateSubscription] }
    
    var items: [TableItemModel] {
        switch self {
        case .action:
            return actionSection
        case .purchases:
            return purchaseSection
        }
    }
}
