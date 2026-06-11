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
        static let bundleIdentifier = "com.karakuts.VaultClip"
        static let legacyBundleIdentifier = "MatthewDavidson.Yippy"
    }
    
    struct panel {
        static let menuWidth: CGFloat = 430
        static let menuHeight: CGFloat = 300
        static let maxCellHeight: CGFloat = HistoryListTheme.metrics.maxCellHeight
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
            HistoryListTheme.typography.body
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

        static var pasteboardDebugLog: URL {
            return appSupport.appendingPathComponent("pasteboard-debug.log", isDirectory: false)
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
