//
//  PaymentQueueController.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation
import StoreKit


/// To be changed if needed
public class PaymentModel: Hashable {
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
    
    public static func == (lhs: PaymentModel, rhs: PaymentModel) -> Bool {
        return lhs.product.productIdentifier == rhs.product.productIdentifier
    }
}

/**
 Defines required callback properties for objects
 that need to observe state changes of `PaymentQueueController` instance.
 */
@objc protocol PaymentQueueObserver: class {
    var onPurchase: ((_ itemTransactionIds: [String]) -> Void)? { get set }
    var onRestore: ((_ items: [SKPaymentTransaction]) -> Void)? { get set }
    var onError: ((_ error: Error) -> Void)? { get set }
    var onRestoreRequested: (() -> Void)? { get set }
}

/**
 - important: Some notes about how requests are processed by SKPaymentQueue:
 - SKPaymentQueue is used to queue payments or restore purchases requests.
 - Payments are processed serially and in-order and require user interaction.
 - Restore purchases requests don't require user interaction and can jump ahead of the queue.
 - SKPaymentQueue rejects multiple restore purchases calls.
 - Having one payment queue observer for each request causes extra processing
 - Failed transactions only ever belong to queued payment requests.
 - restoreCompletedTransactionsFailedWithError is always called when a restore purchases request fails.
 - paymentQueueRestoreCompletedTransactionsFinished is always called following 0 or more update transactions when a restore purchases request succeeds.
 - A complete transactions handler is require to catch any transactions that are updated when the app is not running.
 - Registering a complete transactions handler when the app launches ensures that any pending transactions can be cleared.
 - If a complete transactions handler is missing, pending transactions can be mis-attributed to any new incoming payments or restore purchases.
 
 The order in which transaction updates are processed is:
 1. payments (transactionState: .purchased and .failed for matching product identifiers)
 2. restore purchases (transactionState: .restored, or restoreCompletedTransactionsFailedWithError, or paymentQueueRestoreCompletedTransactionsFinished)
 3. complete transactions (transactionState: .purchased, .failed, .restored, .deferred)
 - Note:
 Any transactions where state == .purchasing are ignored.
 */
final class PaymentQueueController: NSObject {
    
    /**
     - note: We need to keep restored items as class property, because
     actual restoration completion happens in two separate methods,
     while all other types transaction are processed in
     
     `paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])`
     */
    private var restoredTransactions = [SKPaymentTransaction]()
    
    private let paymentQueue: SKPaymentQueue
    private var payments = Set<PaymentModel>()
    public let observers = DelegatesContainer<PaymentQueueObserver>()
    public var storage: Storage
    
    init(paymentQueue: SKPaymentQueue = SKPaymentQueue.default(), storage: Storage) {
        self.paymentQueue = paymentQueue
        self.storage = storage
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
    
    func completeTransaction(for purchasedItem: InAppPurchase) {
        guard let transaction = paymentQueue.transactions.first(where: { $0.transactionIdentifier == purchasedItem.transactionId}) else {
            print("no transactions with id:", purchasedItem.transactionId)
            return
        }
        paymentQueue.finishTransaction(transaction)
    }
    
    func completeTransactions() {
        let transactions = paymentQueue.transactions
        transactions.forEach({ paymentQueue.finishTransaction($0) })
    }
    
    func restore() {
        paymentQueue.restoreCompletedTransactions()
        observers.invokeDelegates({$0.onRestoreRequested?()})
    }
    
    func addObserver(_ observer: PaymentQueueObserver) {
        observers.add(delegate: observer)
    }
    
    func removeObserver(_ observer: PaymentQueueObserver) {
        observers.remove(delegate: observer)
    }
}

// MARK: - SKPaymentTransactionObserver
extension PaymentQueueController: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        var purchased = [InAppPurchase]()
        var errors = [Error]()
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                if let purchasedItem = handlePurchased(transaction: transaction) {
                    purchased.append(purchasedItem)
                }
            case .failed:
                errors.append(handleFailed(transaction: transaction))
            case .restored:
                let restoredTransaction = handleRestored(transaction: transaction)
                if !restoredTransactions.contains(where: { restoredTransaction.transactionIdentifier == $0.transactionIdentifier}) {
                    restoredTransactions.append(restoredTransaction)
                }
            case .deferred:
                break
            case .purchasing:
                break
            }
        }
        
        if purchased.count > 0 {
            storage.persistPurchased(products: purchased)
            observers.invokeDelegates({ $0.onPurchase?(purchased.map({$0.transactionId}))})
        }
        
        if let error = errors.last {
            observers.invokeDelegates({ $0.onError?(error)})
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        observers.invokeDelegates({ $0.onError?(error)})
        restoredTransactions.removeAll()
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        if restoredTransactions.count > 0 {
            observers.invokeDelegates({ $0.onRestore?(restoredTransactions)})
        }
        restoredTransactions.removeAll()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {
        
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return false
    }
}

private extension PaymentQueueController {
    
    private func handlePurchased(transaction: SKPaymentTransaction) -> InAppPurchase? {
        // if there's no payment that corresponds the transaction,
        // complete this transaction instantly
        guard let paymentModel = payments[transaction.payment.productIdentifier] else {
            paymentQueue.finishTransaction(transaction)
            return nil
        }
        if paymentModel.atomic {
            paymentQueue.finishTransaction(transaction)
        }
        payments.remove(paymentModel)
        let item = InAppPurchase(paymentModel: paymentModel,
                                 transaction: transaction,
                                 originalTransaction: transaction.original)
        return item
    }
    
    private func handleRestored(transaction: SKPaymentTransaction) -> SKPaymentTransaction {
        paymentQueue.finishTransaction(transaction)
        return transaction
    }
    
    private func handleFailed(transaction: SKPaymentTransaction) -> Error {
        paymentQueue.finishTransaction(transaction)
        return transaction.error ?? PurchaseError.unknown
    }
}

fileprivate extension Set where Element: PaymentModel {
    subscript(productIdentifier: String) -> Element? {
        return self.first(where: { $0.payment.productIdentifier == productIdentifier })
    }
}
