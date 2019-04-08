//
//  DateFormat+Extensions.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

enum DateFormat: String {
    case datePst = "yyyy-MM-dd HH:mm:ss VV"
}

extension DateFormatter {
    convenience init(dateStyle: DateFormatter.Style) {
        self.init()
        self.dateStyle = dateStyle
    }
    
    convenience init(dateFormat: DateFormat) {
        self.init()
        self.dateFormat = dateFormat.rawValue
    }
}
