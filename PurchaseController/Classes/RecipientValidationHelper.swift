//
//  String+Extensions.swift
//  RecipientValidationHelper
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

/// Function, used create recipient validation info from dte.
///
///
public class RecipientValidationHelper {
    
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
