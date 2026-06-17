//
// LoginServiceKit.swift — vendored login-items helper (Clipy / Google, Apache 2.0).
//
// LoginServiceKit — GitHub: https://github.com/clipy/LoginServiceKit
// Copyright © 2015-2019 Clipy Project.
//
// Portions copyright 2008-2009 Google Inc. (Apache License 2.0).
//

import Cocoa

public final class LoginServiceKit: NSObject {}

public extension LoginServiceKit {
    static func isExistLoginItems(at path: String = Bundle.main.bundlePath) -> Bool {
        return loginItem(at: path) != nil
    }

    @discardableResult
    static func addLoginItems(at path: String = Bundle.main.bundlePath) -> Bool {
        guard !isExistLoginItems(at: path) else { return false }

        guard let sharedFileList = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil) else { return false }
        let loginItemList = sharedFileList.takeRetainedValue()
        let url = URL(fileURLWithPath: path)
        let hiddenKey = kLSSharedFileListLoginItemHidden.takeUnretainedValue() as String
        let properties = [hiddenKey: kCFBooleanTrue as Any] as CFDictionary
        guard let item = LSSharedFileListInsertItemURL(
            loginItemList,
            kLSSharedFileListItemBeforeFirst.takeRetainedValue(),
            nil,
            nil,
            url as CFURL,
            properties,
            nil
        ) else {
            return false
        }
        LSSharedFileListItemSetProperty(item, kLSSharedFileListLoginItemHidden.takeUnretainedValue(), kCFBooleanTrue)
        return true
    }

    @discardableResult
    static func removeLoginItems(at path: String = Bundle.main.bundlePath) -> Bool {
        guard isExistLoginItems(at: path) else { return false }

        guard let sharedFileList = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil) else { return false }
        let loginItemList = sharedFileList.takeRetainedValue()
        let url = URL(fileURLWithPath: path)
        guard let snapshot = LSSharedFileListCopySnapshot(loginItemList, nil) else { return false }
        let loginItemsListSnapshot: NSArray = snapshot.takeRetainedValue()
        guard let loginItems = loginItemsListSnapshot as? [LSSharedFileListItem] else { return false }
        for loginItem in loginItems {
            guard let resolvedUrl = LSSharedFileListItemCopyResolvedURL(loginItem, 0, nil) else { continue }
            let itemUrl = resolvedUrl.takeRetainedValue() as URL
            guard url.absoluteString == itemUrl.absoluteString else { continue }
            LSSharedFileListItemRemove(loginItemList, loginItem)
        }
        return true
    }
}

private extension LoginServiceKit {
    static func loginItem(at path: String) -> LSSharedFileListItem? {
        guard !path.isEmpty else { return nil }

        guard let sharedFileList = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil) else { return nil }
        let loginItemList = sharedFileList.takeRetainedValue()
        let url = URL(fileURLWithPath: path)
        guard let snapshot = LSSharedFileListCopySnapshot(loginItemList, nil) else { return nil }
        let loginItemsListSnapshot: NSArray = snapshot.takeRetainedValue()
        guard let loginItems = loginItemsListSnapshot as? [LSSharedFileListItem] else { return nil }
        for loginItem in loginItems {
            guard let resolvedUrl = LSSharedFileListItemCopyResolvedURL(loginItem, 0, nil) else { continue }
            let itemUrl = resolvedUrl.takeRetainedValue() as URL
            guard url.absoluteString == itemUrl.absoluteString else { continue }
            return loginItem
        }
        return nil
    }
}
