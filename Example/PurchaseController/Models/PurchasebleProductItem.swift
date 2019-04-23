//
//  PurchasebleProductItem.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

enum PurchasebleProductItem: String {
    case consumable = "dashdevs.PurchaseController.Consumable"
    case nonConsumable = "dashdevs.PurchaseController.NonConsumable"
    case autoRenewSubscription = "dashdevs.PurchaseController.Autorenew"
    case nonRenewSubscription = "dashdevs.PurchaseController.NonRenewSubscription"
    
    static let all: [PurchasebleProductItem] = [.consumable, .nonConsumable, .autoRenewSubscription, .nonRenewSubscription]
    
    static func allAsRaw() -> Set<String> {
        let values = PurchasebleProductItem.all.map { $0.rawValue }
        return Set(values)
    }
}
