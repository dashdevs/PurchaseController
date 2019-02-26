//
//  MainViewController.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import UIKit
import PurchaseController

@objc protocol MainViewControllerPresentable: NSObjectProtocol {
    @objc func purchaseConsumable() 
    @objc func purchaseNonConsumable()
    @objc func purchaseAutoRenewSubscription()
    @objc func purchaseNonRenewSubscription()
    @objc func restore()
    @objc func retrieve()
    @objc func validateReceipt()
    @objc func validateSubscription()
}

class MainViewController: UITableViewController {
    lazy var tableController = { return MainTableController(presentableDelegate: self) }()
    lazy var purchaseController = { return PurchaseController(stateHandler: self) }()
    
    override func viewDidLoad() {
        self.tableView.dataSource = tableController
        self.tableView.delegate = tableController
        purchaseController.completeTransactions()
    }
}

extension MainViewController: PurchaseStateHandler {
    func update(newState: PurchaseActionState, from state: PurchaseActionState) {
        switch (state, newState) {
            
        case ( .loading, .finish(let result)):
            switch (result) {
            case  .error(let error):
                print("--- Error occured: \(error)")
            case .subscriptionValidationSucess(let receipt):
                print("--- Moved to state: subscriptionValidationSucess with \(receipt)")
            default:
                print("--- Moved to state: \(newState)")
            }
            
        default: print("--- State changing to \(newState)")
        }
    }
}

extension MainViewController: MainViewControllerPresentable {
    
    @objc func purchaseConsumable() {
        purchaseController.purchase(with: PurchasebleProductItem.consumable.rawValue)
    }
    
    @objc func purchaseNonConsumable() {
        purchaseController.purchase(with: PurchasebleProductItem.nonConsumable.rawValue)
    }
    
    @objc func purchaseAutoRenewSubscription() {
        purchaseController.purchase(with: PurchasebleProductItem.autoRenewSubscription.rawValue)
    }
    
    @objc func purchaseNonRenewSubscription() {
        purchaseController.purchase(with: PurchasebleProductItem.nonRenewSubscription.rawValue)
    }
    
    @objc func restore() {
        purchaseController.restore()
    }
    
    @objc func retrieve() {
        purchaseController.retrieve(products: PurchasebleProductItem.allAsRaw())
    }
    
    @objc func validateReceipt() {
        purchaseController.verifyReceipt(sharedSecret: "d9700a193d4a4b63af22962bd2c7557e")
    }
    
    @objc func validateSubscription() {
        purchaseController.validateSubscription(productID: PurchasebleProductItem.autoRenewSubscription.rawValue, type: .autoRenewable)
    }
    
}