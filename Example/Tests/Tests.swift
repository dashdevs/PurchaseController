import XCTest
@testable import PurchaseController

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    func testPerformanceExample() {
        if let url = Bundle.main.url(forResource: "receipt", withExtension: "json"),  let data = try? Data(contentsOf: url){
            XCTAssertNotNil(RecipientValidationHelper.createRecipientValidation(from: data))
        }
    }
    
}
