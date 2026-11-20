//
// PasswordPrivacySurfaces — collect UI strings that must not leak secrets (U23).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

struct PasswordPrivacyFixture: Equatable {
    var secret: String
    var comment: String
    var login: String
    var url: String
}

enum PasswordPrivacySurfaces {
    /// Strings shown on panel surfaces before explicit reveal.
    static func visibleStrings(
        fixture: PasswordPrivacyFixture,
        rowTitle: String,
        rowSubtitle: String,
        accessibilityLabel: String,
        previewComment: String,
        previewLogin: String,
        previewURL: String,
        maskedPassword: String = "••••••••",
        searchHaystack: String
    ) -> [String] {
        [
            rowTitle,
            rowSubtitle,
            accessibilityLabel,
            previewComment,
            previewLogin,
            previewURL,
            maskedPassword,
            searchHaystack
        ]
    }

    static func assertSecretAbsent(in surfaces: [String], secret: String) -> Bool {
        guard !secret.isEmpty else { return true }
        return surfaces.allSatisfy { !$0.contains(secret) }
    }
}

final class PasswordRevealAutoHide {
    static let hideAfter: TimeInterval = 30
    private let now: () -> Date
    private var revealedAt: Date?

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    var isRevealed: Bool {
        guard let revealedAt else { return false }
        return now().timeIntervalSince(revealedAt) < Self.hideAfter
    }

    func reveal() { revealedAt = now() }
    func hide() { revealedAt = nil }
}
