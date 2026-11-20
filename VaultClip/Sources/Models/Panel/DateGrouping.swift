//
// DateGrouping — history list day/week/month buckets by lastUsedAt (U12).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum DateGroupBucket: Equatable, Hashable {
    case today
    case yesterday
    case last7Days
    case last30Days
    case month(year: Int, month: Int)
}

enum DateGrouping {
    static func bucket(for date: Date, now: Date, calendar: Calendar) -> DateGroupBucket {
        // Use `now` as the reference day so tests can inject a fixed "today".
        if calendar.isDate(date, inSameDayAs: now) { return .today }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return .yesterday
        }
        let startOfToday = calendar.startOfDay(for: now)
        if let seven = calendar.date(byAdding: .day, value: -7, to: startOfToday), date >= seven {
            return .last7Days
        }
        if let thirty = calendar.date(byAdding: .day, value: -30, to: startOfToday), date >= thirty {
            return .last30Days
        }
        let comps = calendar.dateComponents([.year, .month], from: date)
        return .month(year: comps.year ?? 0, month: comps.month ?? 1)
    }

    static func title(for bucket: DateGroupBucket, now: Date, calendar: Calendar, locale: Locale) -> String {
        let ru = locale.language.languageCode?.identifier == "ru"
        switch bucket {
        case .today: return ru ? "Сегодня" : "Today"
        case .yesterday: return ru ? "Вчера" : "Yesterday"
        case .last7Days: return ru ? "Последние 7 дней" : "Previous 7 Days"
        case .last30Days: return ru ? "Последние 30 дней" : "Previous 30 Days"
        case .month(let year, let month):
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = 1
            guard let date = calendar.date(from: comps) else { return "" }
            let formatter = DateFormatter()
            formatter.locale = locale
            let currentYear = calendar.component(.year, from: now)
            formatter.setLocalizedDateFormatFromTemplate(year == currentYear ? "MMMM" : "MMMM yyyy")
            return formatter.string(from: date)
        }
    }
}
