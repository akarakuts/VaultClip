//
//  FileManagerMock.swift
//  VaultClipTests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

class FileManagerMock: FileManager {
    
    var directoryContents = [URL: [URL]?]()
    
    var createDirectory = [URL: Bool]()
    
    var removeItem = [URL: Bool]()

    var fileExists = [String: Bool]()

    override func fileExists(atPath path: String) -> Bool {
        if let exists = fileExists[path] {
            return exists
        }
        if directoryContents.keys.contains(URL(fileURLWithPath: path)) {
            return true
        }
        return super.fileExists(atPath: path)
    }

    override func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        if let exists = fileExists[path] {
            isDirectory?.pointee = ObjCBool(directoryContents.keys.contains(URL(fileURLWithPath: path)))
            return exists
        }
        if directoryContents.keys.contains(URL(fileURLWithPath: path)) {
            isDirectory?.pointee = true
            return true
        }
        return super.fileExists(atPath: path, isDirectory: isDirectory)
    }
    
    override func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions = []) throws -> [URL] {
        if let contents = directoryContents[url] as? [URL] {
            return contents
        }
        else {
            throw NSError(domain: "FileManagerTests", code: 0)
        }
    }
    
    override func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
        if createDirectory[url] == nil || createDirectory[url] == false {
            throw NSError(domain: "FileManagerTests", code: 0)
        }
    }
    
    override func removeItem(at URL: URL) throws {
        if removeItem[URL] == nil || removeItem[URL] == false {
            throw NSError(domain: "FileManagerTests", code: 0)
        }
    }
}
