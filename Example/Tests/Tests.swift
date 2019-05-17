import XCTest
@testable import PurchaseController

class Tests: XCTestCase {

    func testPerformance() {
        measure {
            if let url = Bundle.main.url(forResource: "receipt", withExtension: "json"),  let data = try? Data(contentsOf: url) {
                XCTAssertNotNil(ReceiptValidationHelper.createReceiptValidation(from: data))
            }
        }
    }
    
    func testPerformanceSmallReceipt() {
        if let url = Bundle.main.url(forResource: "receiptJson", withExtension: "json"),  let data = try? Data(contentsOf: url) {
            XCTAssertNotNil(ReceiptValidationHelper.createReceiptValidation(from: data))
        }
    }
}

