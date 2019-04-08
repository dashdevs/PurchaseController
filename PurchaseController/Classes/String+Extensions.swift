//
//  String+Extensions.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//
import Foundation

extension String {
    func date() -> Date? {
        guard let ms = TimeInterval(self) else {
            return nil
        }
        return Date(timeIntervalSince1970: ms / 1000)
    }
}
