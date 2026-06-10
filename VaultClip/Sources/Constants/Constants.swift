//
//  Constants.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

struct Constants {

    /// User-visible application name (menu bar, alerts, system permission strings).
    struct branding {
        static let displayName = "VaultClip"
        static let bundleIdentifier = "VaultClip"
        static let legacyBundleIdentifier = "MatthewDavidson.Yippy"
        static let historyTabTitle = "History"
        static let favoritesTabTitle = "Favorites"
        static let passwordsTabTitle = "Passwords"
    }
    
    struct panel {
        static let menuWidth: CGFloat = 430
        static let menuHeight: CGFloat = 300
        static let maxCellHeight: CGFloat = 200
    }
    
    struct statusItemMenu {
        static let deleteKeyEquivalent = NSString(format: "%c", NSDeleteCharacter) as String
        static let leftArrowKeyEquivalent = NSString(format: "%C", 0x001c) as String
        static let rightArrowKeyEquivalent = NSString(format: "%C", 0x001d) as String
        static let downArrowKeyEquivalent = NSString(format: "%C", 0x001f) as String
        static let upArrowKeyEquivalent = NSString(format: "%C", 0x001e) as String
    }
    
    struct fonts {
        
        static var listPlainText: NSFont {
            if #available(OSX 10.15, *) {
                return NSFont(name: "SF Mono Regular", size: 12) ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
//                return NSFont(name: "Roboto Mono Light for Powerline", size: 12) ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            }
            else {
                return NSFont(name: "Roboto Mono Light for Powerline", size: 12) ?? NSFont.systemFont(ofSize: 12)
            }
        }
        
        static var listFileNameText: NSFont {
            listPlainText
        }
    }
    
    struct urls {
        static var applicationSupport: URL {
            return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        }
        
        static var appSupport: URL {
            return applicationSupport.appendingPathComponent(Constants.branding.bundleIdentifier, isDirectory: true)
        }

        static var legacyAppSupport: URL {
            return applicationSupport.appendingPathComponent(Constants.branding.legacyBundleIdentifier, isDirectory: true)
        }
        
        static var history: URL {
            return appSupport.appendingPathComponent("history", isDirectory: true)
        }
        
        static var historyOrder: URL {
            return history.appendingPathComponent("order.xml", isDirectory: false)
        }
        
        static var errorLog: URL {
            return appSupport.appendingPathComponent("error.log", isDirectory: false)
        }
        
        static var warningLog: URL {
            return appSupport.appendingPathComponent("warning.log", isDirectory: false)
        }
    }
    
    struct logging {
        
        static let historyErrorDomain = "VaultClipHistoryErrorDomain"
        
        static let historyWarningDomain = "VaultClipHistoryWarningDomain"
    }
    
    struct system {
        
        static let maxHistoryItems = 5000
    }
    
    struct settings {
        
        static let maxHistoryItemsOptions = [50, 100, 200, 500, 750, 1000, 1500]
        
        static let maxHistoryItemsDefaultIndex = 3
        
        static let maxHistoryItemsDefault = Constants.settings.maxHistoryItemsOptions[Constants.settings.maxHistoryItemsDefaultIndex]
    }
}
