//  AppleReceiptValidatorImplementation.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.

import Foundation
import SwiftyStoreKit


/// Implementation of appStore receipt validator.
///
///  - Important:
/// Do not call the App Store server /verifyReceipt endpoint from your app.
/// # See also
/// [Receipt Validation](https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html)
public struct AppleReceiptValidatorImplementation: ReceiptValidatorProtocol {
    
    // MARK: - Properties
    
    /// Shared secret from Appstore Connect.
    ///
    /// # See also
    /// [Shared secret key for in-app purchase](https://www.appypie.com/faqs/how-can-i-get-shared-secret-key-for-in-app-purchase)
    let sharedSecret: String?
    
    /// Defines is there sandbox environment or not.
    let isSandbox: Bool
    
    // MARK: - Lifecycle
    
    public init(sharedSecret: String?, isSandbox: Bool) {
        self.sharedSecret = sharedSecret
        self.isSandbox = isSandbox
    }
    
    // MARK: - Public methods
    
    public func validate(completion: @escaping (ReceiptValidationResult) -> Void) {
        let appleValidator = AppleReceiptValidator(service: isSandbox ? .sandbox : .production,
                                                   sharedSecret: sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            switch result {
            case .success(let receiptInfo):
                self.decode(receiptInfo: receiptInfo, completion: completion)
            case .error(let error):
                completion(.error(error: error))
            }
        }
    }
    
    // MARK: - Private methods
    
    private func decode(receiptInfo: ReceiptInfo, completion: @escaping (ReceiptValidationResult) -> Void) {
        let validation = receiptInfo.createReceiptValidation()
        if let receipt = validation.response?.receipt {
            completion(.success(receipt: receipt))
        } else if let error = validation.error {
            completion(.error(error: error))
        } else {
            completion(.error(error: PurchaseError.receiptSerializationError.asNSError()))
        }
    }
}
