//
// ColorFormatTests — HEX/RGB/HSL/P3 (U22).
//
import XCTest
@testable import VaultClip

final class ColorFormatTests: XCTestCase {
    func testOpaqueRed() {
        let c = ColorComponents(red: 1, green: 0, blue: 0, alpha: 1)
        XCTAssertEqual(ColorFormat.hex(from: c), "#FF0000")
        XCTAssertEqual(ColorFormat.rgb(from: c), "rgb(255, 0, 0)")
        XCTAssertTrue(ColorFormat.hsl(from: c).hasPrefix("hsl(0,"))
        XCTAssertEqual(ColorFormat.displayP3(from: c), "color(display-p3 1.000 0.000 0.000)")
    }
}
