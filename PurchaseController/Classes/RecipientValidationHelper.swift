//
//  String+Extensions.swift
//  RecipientValidationHelper
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

public class RecipientValidationHelper {
    
    /// Function used to create readable representation of receipt from data
    ///
    /// - Parameter data: data to decode
    /// - Returns: readable representation of data
    static func createRecipientValidation(from data: Data) -> ReceiptValidationResponse? {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(ReceiptValidationResponse.self, from: data)
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }

}
