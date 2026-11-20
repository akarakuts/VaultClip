//
// PerformanceBudget — presenter/filter timing helpers (U35).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum PerformanceBudget {
    /// Hard CI limit for 5k synthetic present/filter (ms).
    static let presentFilterLimitMs: Double = 200

    /// TSan inflates timings several×; keep the non-TSan budget honest.
    static var effectivePresentFilterLimitMs: Double {
        isThreadSanitizerRuntime ? presentFilterLimitMs * 5 : presentFilterLimitMs
    }

    /// `THREAD_SANITIZER` is not always defined for Swift; detect the injected runtime.
    static var isThreadSanitizerRuntime: Bool {
        if let inserted = getenv("DYLD_INSERT_LIBRARIES") {
            return String(cString: inserted).contains("libclang_rt.tsan")
        }
        return getenv("TSAN_OPTIONS") != nil
    }
    static func measureMs(_ work: () -> Void) -> Double {
        let start = CFAbsoluteTimeGetCurrent()
        work()
        return (CFAbsoluteTimeGetCurrent() - start) * 1000
    }

    static func syntheticSummaries(count: Int, now: Date = Date()) -> [ItemSummary] {
        (0..<count).map { i in
            ItemSummary(
                title: "Item \(i)",
                charCount: 10,
                lineCount: 1,
                linkHost: nil,
                fileNames: [],
                imagePixelSize: nil,
                imageFormat: nil,
                colorHex: nil,
                sourceBundleId: i % 3 == 0 ? "com.apple.Safari" : "com.apple.TextEdit",
                copiedAt: now.addingTimeInterval(TimeInterval(-i)),
                lastUsedAt: now.addingTimeInterval(TimeInterval(-i)),
                kind: i % 5 == 0 ? .link : .text,
                passwordComment: nil,
                pdfPageCount: nil,
                isRichText: false
            )
        }
    }
}
