//
//  PaymentQueueController.swift
//  PurchaseController
//
//  Created by Igor Kulik on 7/3/19.
//

import Foundation
import StoreKit


/// To be changed for sure
fileprivate class PaymentModel: Hashable {
    let product: SKProduct
    let payment: SKPayment
    let atomic: Bool
    
    
    init(product: SKProduct, payment: SKPayment, atomic: Bool) {
        self.product = product
        self.payment = payment
        self.atomic = atomic
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(product.productIdentifier)
    }

    static func == (lhs: PaymentModel, rhs: PaymentModel) -> Bool {
        return lhs.product.productIdentifier == rhs.product.productIdentifier
    }
}

protocol PaymentQueueControllerDelegate: class {
    func didPurchase(_ controller: PCPaymentQueueController, item: PurchaseItem)
    func didFail(_ controller: PCPaymentQueueController, error: Error)
}

extension PaymentQueueControllerDelegate {
    deinit {
        print("foo")
    }
}

/**
 * - important: Some notes about how requests are processed by SKPaymentQueue:
 *
 * - SKPaymentQueue is used to queue payments or restore purchases requests.
 * - Payments are processed serially and in-order and require user interaction.
 * - Restore purchases requests don't require user interaction and can jump ahead of the queue.
 * - SKPaymentQueue rejects multiple restore purchases calls.
 * - Having one payment queue observer for each request causes extra processing
 * - Failed transactions only ever belong to queued payment requests.
 * - restoreCompletedTransactionsFailedWithError is always called when a restore purchases request fails.
 * - paymentQueueRestoreCompletedTransactionsFinished is always called following 0 or more update transactions when a restore purchases request succeeds.
 * - A complete transactions handler is require to catch any transactions that are updated when the app is not running.
 * - Registering a complete transactions handler when the app launches ensures that any pending transactions can be cleared.
 * - If a complete transactions handler is missing, pending transactions can be mis-attributed to any new incoming payments or restore purchases.
 *
 * The order in which transaction updates are processed is:
 * 1. payments (transactionState: .purchased and .failed for matching product identifiers)
 * 2. restore purchases (transactionState: .restored, or restoreCompletedTransactionsFailedWithError, or paymentQueueRestoreCompletedTransactionsFinished)
 * 3. complete transactions (transactionState: .purchased, .failed, .restored, .deferred)
 * - Note:
 * Any transactions where state == .purchasing are ignored.
 */
final class PCPaymentQueueController: NSObject {
    
    private let paymentQueue: SKPaymentQueue
    private var payments = Set<PaymentModel>()
    private let delegates = WeakArray<PaymentQueueControllerDelegate>()
    
    init(paymentQueue: SKPaymentQueue = SKPaymentQueue.default()) {
        self.paymentQueue = paymentQueue
        super.init()
        paymentQueue.add(self)
    }

    func purchase(product: SKProduct,
                  quantity: Int = 1,
                  atomically: Bool = true,
                  applicationUsername: String = "",
                  simulatesAskToBuyInSandbox: Bool = false) {
        let payment = SKMutablePayment(product: product)
        payment.quantity = quantity
        paymentQueue.add(payment)
        payments.insert(PaymentModel(product: product, payment: payment, atomic: atomically))
    }
}

// MARK: - SKPaymentTransactionObserver
extension PCPaymentQueueController: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                complete(transaction: transaction)
                break
            case .failed:
                fail(transaction: transaction)
                break
            case .restored:
                restore(transaction: transaction)
                break
            case .deferred:
                break
            case .purchasing:
                break
            }
        }

    }
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {
        
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return false
    }
}

private extension PCPaymentQueueController {
    

    private func complete(transaction: SKPaymentTransaction) {
        print("complete...", transaction)
        guard let paymentModel = payments[transaction.payment.productIdentifier] else {
            // TODO: specific error
            return
        }
        if paymentModel.atomic {
                SKPaymentQueue.default().finishTransaction(transaction)
        }
        payments.remove(paymentModel)
    }
    
    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        
        print("restore... \(productIdentifier)")
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        print("fail...")
        if let transactionError = transaction.error as NSError?,
            let localizedDescription = transaction.error?.localizedDescription,
            transactionError.code != SKError.paymentCancelled.rawValue {
            print("Transaction Error: \(localizedDescription)")
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
}

fileprivate extension Set where Element: PaymentModel {
    subscript(productIdentifier: String) -> Element? {
        return self.first(where: { $0.payment.productIdentifier == productIdentifier })
    }
}

