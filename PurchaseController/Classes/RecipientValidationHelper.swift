//
//  String+Extensions.swift
//  ReceiptValidationHelper
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation
import SwiftyStoreKit

public class ReceiptValidationHelper {
    
    /// Function used to create readable representation of receipt from dictionary
    ///
    /// - Parameter receipt: dictionary receipt
    /// - Returns: readable representation of receipt or error
    public static func createReceiptValidation(from receipt: ReceiptInfo) -> (response: ReceiptValidationResponse?, error: Error?) {
        do {
            let data = try JSONSerialization.data(withJSONObject: receipt)
            let response = try createReceiptResponse(data: data)
            return (response, nil)
        } catch {
            return (nil, error)
        }
    }
    
    /// Function used to create readable representation of receipt from data
    ///
    /// - Parameter receipt: receipt data
    /// - Returns: readable representation of data
    public static func createReceiptValidation(from receipt: Data) -> ReceiptValidationResponse? {
        do {
            return try createReceiptResponse(data: receipt)
        } catch {
            return nil
        }
    }
    
    // MARK: - Private
    
    /// Function used to create receipt object from data
    ///
    /// - Parameter data: receipt data
    /// - Returns: readable representation of data
    /// - Throws: an error if any value throws an error during decoding
    private static func createReceiptResponse(data: Data) throws -> ReceiptValidationResponse? {
        let response = try JSONDecoder().decode(ReceiptValidationResponse.self, from: data)
        return response
    }
}
