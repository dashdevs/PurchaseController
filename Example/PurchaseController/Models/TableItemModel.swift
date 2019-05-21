//
//  TableItemModel.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

enum TableItemModel: String {
    
    case consumable
    case nonConsumable
    case autoRenewSubscription
    case nonRenewSubscription
    
    case restore
    case retrieve
    case refreshReceipt
    case validateReceipt
    case decodeReceipt
    case synchronizePurchases
    case validateSubscription
    
    var title: String {
        switch self {
        case .consumable:
            return "Consumable 💰"
        case .nonConsumable:
            return "Non Consumable 💸"
        case .autoRenewSubscription:
            return "Auto Renew Subscription 🤑"
        case .nonRenewSubscription:
            return "Non Renew Subscription 💵"
            
        case .restore:
            return "Restore 💲"
        case .retrieve:
            return "Retrieve 💶"
        case .refreshReceipt:
            return "Refresh receipt 🧾"
        case .validateReceipt:
            return "Validate receipt 💴"
        case .decodeReceipt:
            return "Decode receipt 🧾"
        case .synchronizePurchases:
            return "Synchronize purchases ↕"
        case .validateSubscription:
            return "Validate subscription 💴"
        }
    }
    
    var action: Selector {
        switch self {
        case .consumable:
            return #selector(MainViewController.purchaseConsumable)
        case .nonConsumable:
            return #selector(MainViewController.purchaseNonConsumable)
        case .autoRenewSubscription:
            return #selector(MainViewController.purchaseAutoRenewSubscription)
        case .nonRenewSubscription:
            return #selector(MainViewController.purchaseNonRenewSubscription)
            
        case .restore:
            return #selector(MainViewController.restore)
        case .retrieve:
            return #selector(MainViewController.retrieve)
        case .refreshReceipt:
            return #selector(MainViewController.updateReceipt)
        case .validateReceipt:
            return #selector(MainViewController.validateReceipt)
        case .decodeReceipt:
            return #selector(MainViewController.decodeReceipt)
        case .synchronizePurchases:
            return #selector(MainViewController.synchronizePurchases)
        case .validateSubscription:
            return #selector(MainViewController.validateSubscription)

        }
    }
}
