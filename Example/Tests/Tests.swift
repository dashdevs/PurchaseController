import XCTest
@testable import PurchaseController

class Tests: XCTestCase {

    func testPerformanceExample() {
        measure {
            if let url = Bundle.main.url(forResource: "receipt", withExtension: "json"),  let data = try? Data(contentsOf: url){
                XCTAssertNotNil(RecipientValidationHelper.createRecipientValidation(from: data))
            }
        }
    }
}
