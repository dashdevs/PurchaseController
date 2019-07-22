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
    @objc func refreshReceipt()
    @objc func validateReceiptLocally()
    @objc func validateReceiptRemotely()
    @objc func validateSubscription()
    @objc func showNewVC()
}

class MainViewController: UITableViewController {
    lazy var tableController = { return MainTableController(presentableDelegate: self) }()
    lazy var purchaseController = { return PurchaseController(stateHandler: self, productIds: PurchasebleProductItem.allAsRaw())}()
    
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
            case .error(let error):
                print("--- Error occured: \(error)")
            case .subscriptionValidationSuccess(let receipt):
                print("--- Moved to state: subscriptionValidationSucess with \(receipt)")
            case .purchaseSuccess(let item):
                print("--- Moved to state: purchaseSuccess with \(item)")
            default:
                print("--- Moved to state: \(newState)")
            }
            
        default: print("--- State changing to \(newState)")
        }
    }
}

extension MainViewController: MainViewControllerPresentable {
    
    @objc func purchaseConsumable() {
        purchaseController.purchase(with: PurchasebleProductItem.consumable.rawValue, atomically: false)
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
        purchaseController.retrieve()
    }
    
    @objc func refreshReceipt() {
        purchaseController.fetchReceipt()
    }
    
    @objc func validateReceiptLocally() {
        purchaseController.validateReceipt(using: LocalReceiptValidatorImplementation())
    }
    
    @objc func validateReceiptRemotely() {
        purchaseController.validateReceipt(using: AppleReceiptValidatorImplementation(sharedSecret: "88038f49a0b74978b2716a9ef7f66470",
                                                                                      isSandbox: true))
    }
    
    @objc func validateSubscription() {
        purchaseController.validateSubscription(filter: nil)
    }
    
    @objc func showNewVC() {
        let newVc = self.storyboard?.instantiateViewController(withIdentifier: "Main")
        self.navigationController?.pushViewController(newVc!, animated: true)
    }
}
