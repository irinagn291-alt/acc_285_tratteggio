import XCTest
@testable import Tratteggio

final class TratteggioTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: TratteggioApp.self), "TratteggioApp")
        XCTAssertEqual(Loupe.currentSchema, 1)
        XCTAssertEqual(LoupeKey.snapshot, "ttg.loupe.v1")
        XCTAssertEqual(CatalogClient.userAgent, "Tratteggio/1.0 (iOS; +https://tratteggio-loupe.pro)")
    }
}
