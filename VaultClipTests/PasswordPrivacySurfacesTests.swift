//
// PasswordPrivacySurfacesTests — secret never appears on surfaces (U23).
//
import XCTest
@testable import VaultClip

final class PasswordPrivacySurfacesTests: XCTestCase {
    func testSecretAbsentFromSurfaces() {
        let fixture = PasswordPrivacyFixture(
            secret: "S3cret!Value",
            comment: "Bank",
            login: "user@example.com",
            url: "https://bank.example"
        )
        let surfaces = PasswordPrivacySurfaces.visibleStrings(
            fixture: fixture,
            rowTitle: fixture.comment,
            rowSubtitle: fixture.login,
            accessibilityLabel: "Password, \(fixture.comment)",
            previewComment: fixture.comment,
            previewLogin: fixture.login,
            previewURL: fixture.url,
            maskedPassword: "••••••••",
            searchHaystack: "\(fixture.comment) \(fixture.login)"
        )
        XCTAssertTrue(PasswordPrivacySurfaces.assertSecretAbsent(in: surfaces, secret: fixture.secret))
    }

    func testAutoHide() {
        var t = Date(timeIntervalSince1970: 1000)
        let clock = PasswordRevealAutoHide(now: { t })
        clock.reveal()
        XCTAssertTrue(clock.isRevealed)
        t = t.addingTimeInterval(PasswordRevealAutoHide.hideAfter)
        XCTAssertFalse(clock.isRevealed)
    }
}
