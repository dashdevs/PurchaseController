//  AppleReceiptValidatorImplementation.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.

import Foundation

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
    

    // MARK: - Private
    
    private enum VerifyReceiptURLType: String {
        case production = "https://buy.itunes.apple.com/verifyReceipt"
        case sandbox = "https://sandbox.itunes.apple.com/verifyReceipt"
    }
    
    private var appStoreReceiptData: Data? {
        guard let receiptDataURL = Bundle.main.appStoreReceiptURL,
            let data = try? Data(contentsOf: receiptDataURL) else {
                return nil
        }
        return data
    }
    
    // MARK: - Lifecycle
    
    public init(sharedSecret: String?, isSandbox: Bool) {
        self.sharedSecret = sharedSecret
        self.isSandbox = isSandbox
    }
    
    // MARK: - Public methods
    
    /**
     * Used to validate receipt using shared secret on apple side. Unsequre
     *
     * - Parameter completion: result of validation
     */
    public func validate(completion: @escaping (ReceiptValidationResult) -> Void) {
        guard let appStoreReceiptData = appStoreReceiptData else {
            completion(.error(error: ReceiptError.noReceiptData))
            return
        }
        self.validate(receiptData: appStoreReceiptData, completion: completion)
    }
    
    // MARK: - Private methods
    
    private func validate(receiptData: Data, completion: @escaping (ReceiptValidationResult) -> Void) {
        let service: VerifyReceiptURLType = isSandbox ? .sandbox : .production
        let storeURL = URL(string: service.rawValue)!
        let storeRequest = NSMutableURLRequest(url: storeURL)
        storeRequest.httpMethod = "POST"
        
        let receipt = receiptData.base64EncodedString(options: [])
        let requestContents: NSMutableDictionary = [ "receipt-data": receipt ]
        guard let password = sharedSecret else {
            completion(.error(error: ReceiptError.secretNotMatching))
            return
        }
        requestContents.setValue(password, forKey: "password")
        do {
            storeRequest.httpBody = try JSONSerialization.data(withJSONObject: requestContents, options: [])
        } catch let error {
            completion(.error(error: error))
            return
        }
        let task = URLSession.shared.dataTask(with: storeRequest as URLRequest) { data, _, error -> Void in
            if let error = error {
                completion(.error(error: error))
                return
            }
            guard let safeData = data else {
                completion(.error(error: ReceiptError.noRemoteData))
                return
            }
            guard let representation = try? safeData.createReceiptResponse(),
                let receiptInfo = representation else {
                completion(.error(error: ReceiptError.noReceiptData))
                return
            }
            
            let status = receiptInfo.status
            /*
             * http://stackoverflow.com/questions/16187231/how-do-i-know-if-an-in-app-purchase-receipt-comes-from-the-sandbox
             * Always verify your receipt first with the production URL; proceed to verify
             * with the sandbox URL if you receive a 21007 status code. Following this
             * approach ensures that you do not have to switch between URLs while your
             * application is being tested or reviewed in the sandbox or is live in the
             * App Store.
             
             * Note: The 21007 status code indicates that this receipt is a sandbox receipt,
             * but it was sent to the production service for verification.
             */
            let receiptError = ReceiptError(with: status)
            if receiptError == .testReceipt {
                let sandboxValidator = AppleReceiptValidatorImplementation(sharedSecret: self.sharedSecret, isSandbox: true)
                sandboxValidator.validate(receiptData: receiptData, completion: completion)
            } else {
                if let finalReceipt = receiptInfo.receipt {
                     completion(.success(receipt: finalReceipt))
                } else {
                    completion(.error(error: receiptError ?? .unknown))
                }
            }
        }
        task.resume()
    }
}
