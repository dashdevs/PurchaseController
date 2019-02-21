//
//  PurchasebleProductItem.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

enum PurchasebleProductItem: String {
    case consumable = "com.tomych.purchaseLecture.consumable"
    case nonConsumable = "com.tomych.purchaseLecture.NonConsumable"
    case autoRenewSubscription = "com.tomych.purchaseLecture.autorenew"
    case nonRenewSubscription = "com.tomych.purchaseLecture.NonRenewSubscription"
    
    static let all: [PurchasebleProductItem] = [.consumable, .nonConsumable]
    
    static func allAsRaw() -> Set<String> {
        let values = PurchasebleProductItem.all.map { $0.rawValue }
        return Set(values)
    }
}
