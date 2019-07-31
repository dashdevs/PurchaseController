//
//  PurchasebleProductItem.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

enum PurchasebleProductItem: String, CaseIterable {
    case consumable = "dashdevs.PurchaseController.Consumable"
    case nonConsumable = "dashdevs.PurchaseController.NonConsumable"
    case autoRenewSubscription = "dashdevs.PurchaseController.Autorenew"
    case nonRenewSubscription = "dashdevs.PurchaseController.NonRenewSubscription"
    case invalid  = "dashdevs.Invalid"
    
    static func allAsRaw() -> Set<String> {
        let values = PurchasebleProductItem.allCases.map { $0.rawValue }
        return Set(values)
    }
}
