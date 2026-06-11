import Foundation

/// Tags for status bar menu items — stable lookup regardless of UI locale.
enum StatusMenuTag: Int {
    case about = 1
    case help = 2
    case preferences = 3
    case toggleWindow = 4
    case launchAtLogin = 5
    case deleteSelected = 6
    case clearHistory = 7
    case position = 8
    case quit = 9
}
