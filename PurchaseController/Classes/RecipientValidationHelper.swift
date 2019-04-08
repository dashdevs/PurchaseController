//
//  RecipientValidationHelper.swift
//  Pods-PurchaseController_Example
//
//

import Foundation

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
