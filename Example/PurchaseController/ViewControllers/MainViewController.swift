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
    @objc func synchronizePurchases()
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
            case .error(let error):
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
        let alert = UIAlertController(title: "", message: "Please enter number of items to purchase", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            textField.keyboardType = .numberPad
        })
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: { [weak self] action in
            guard let strValue = alert.textFields?.first?.text,
                let quantity = Int(strValue) else {
                    self?.showQuantityError()
                    return
            }
            self?.purchaseController.purchase(with: PurchasebleProductItem.consumable.rawValue, quantity: quantity)
        })
        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.preferredAction = okAction
        present(alert, animated: true, completion: nil)
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
    
    @objc func refreshReceipt() {
        purchaseController.fetchReceipt()
    }
    
    @objc func validateReceiptLocally() {
        purchaseController.validateReceipt(using: LocalReceiptValidatorImplementation())
    }
    
    @objc func validateReceiptRemotely() {
        purchaseController.validateReceipt(using: AppleReceiptValidatorImplementation(sharedSecret: nil, isSandbox: true))
    }
    
    @objc func synchronizePurchases() {
        purchaseController.synchronizeLocalPurchasesFromReceipt()
    }
    
    @objc func validateSubscription() {
        purchaseController.validateSubscription(productID: PurchasebleProductItem.autoRenewSubscription.rawValue, type: .autoRenewable)
    }
}

private extension MainViewController {
    func showQuantityError() {
        let alertController = UIAlertController(title: "", message: "Please enter a valid product quantity.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
