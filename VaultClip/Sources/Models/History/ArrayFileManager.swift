//
//  ArrayFileManager.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

class ArrayFileManager {
    
    var url: URL
    private let dataFileManager: DataFileManager
    
    init(url: URL, dataFileManager: DataFileManager = DataFileManager()) {
        self.url = url
        self.dataFileManager = dataFileManager
    }
    
    func write(_ array: NSArray) throws {
        let plist = try PropertyListSerialization.data(fromPropertyList: array, format: .xml, options: 0)
        try dataFileManager.writeData(plist, to: url)
    }
    
    func read() -> NSArray? {
        if let data = try? dataFileManager.loadData(contentsOf: url),
           let list = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? NSArray {
            return list
        }
        if HistoryEncryptionProbe.isEncryptedFile(at: url) {
            return nil
        }
        // Legacy unencrypted order file.
        return NSArray(contentsOf: url)
    }
}
