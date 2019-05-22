//
//  PurchaseController+Extensions.swift
//  ReceiptValidationHelper
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation
import SwiftyStoreKit

extension ReceiptInfo {
    /// Function used to create readable representation of receipt
    ///
    /// - Returns: readable representation of receipt or error
    public func createReceiptValidation() -> (response: ReceiptValidationResponse?, error: Error?) {
        do {
            let data = try JSONSerialization.data(withJSONObject: self)
            let response = try data.createReceiptResponse()
            return (response, nil)
        } catch {
            return (nil, error)
        }
    }
}

extension Data {
    /// Function used to create readable representation of receipt
    ///
    /// - Returns: readable representation of data
    public func createReceiptValidation() -> ReceiptValidationResponse? {
        do {
            return try self.createReceiptResponse()
        } catch {
            return nil
        }
    }
    
    /// Function used to create receipt object
    ///
    /// - Returns: readable representation of data
    /// - Throws: an error if any value throws an error during decoding
    public func createReceiptResponse() throws -> ReceiptValidationResponse? {
        let response = try JSONDecoder().decode(ReceiptValidationResponse.self, from: self)
        return response
    }
}
