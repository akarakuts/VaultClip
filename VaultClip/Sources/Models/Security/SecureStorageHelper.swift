//
//  SecureStorageHelper.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

enum SecureStorageHelper {
    
    static let directoryPermissions: Int16 = 0o700
    
    /// Rejects symlinked paths outside the expected Application Support subtree.
    static func validateStorageURL(_ url: URL, mustResideUnder root: URL, fileManager: FileManager = .default) throws {
        let resolved = url.resolvingSymlinksInPath().standardizedFileURL
        let rootResolved = root.resolvingSymlinksInPath().standardizedFileURL
        let resolvedComponents = resolved.pathComponents
        let rootComponents = rootResolved.pathComponents
        guard resolvedComponents.count >= rootComponents.count,
              Array(resolvedComponents.prefix(rootComponents.count)) == rootComponents else {
            throw SecureStorageError.untrustedPath(resolved.path)
        }
        // New item directories do not exist yet — symlink check applies only to existing paths.
        guard fileManager.fileExists(atPath: url.path) else { return }
        let values = try url.resourceValues(forKeys: [.isSymbolicLinkKey])
        if values.isSymbolicLink == true {
            throw SecureStorageError.symlinkDetected(url.path)
        }
    }
    
    static func ensureSecureDirectory(at url: URL, fileManager: FileManager = .default) throws {
        var isDirectory: ObjCBool = false
        if !fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } else if !isDirectory.boolValue {
            try fileManager.removeItem(at: url)
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        try? fileManager.setAttributes(
            [.posixPermissions: NSNumber(value: directoryPermissions)],
            ofItemAtPath: url.path
        )
    }
    
    static func sanitizedPasteboardFileName(for type: NSPasteboard.PasteboardType) -> String {
        type.rawValue
            .replacingOccurrences(of: "%", with: "%25")
            .replacingOccurrences(of: "/", with: "%2F")
            .replacingOccurrences(of: ":", with: "%3A")
    }
    
    static func pasteboardType(fromStoredFileName fileName: String) -> NSPasteboard.PasteboardType {
        var decoded = ""
        var index = fileName.startIndex
        while index < fileName.endIndex {
            let char = fileName[index]
            if char == "%" {
                let firstIndex = fileName.index(after: index)
                guard firstIndex < fileName.endIndex else {
                    decoded.append("%")
                    index = firstIndex
                    continue
                }
                let secondIndex = fileName.index(after: firstIndex)
                guard secondIndex < fileName.endIndex else {
                    decoded.append("%")
                    decoded.append(fileName[firstIndex])
                    index = secondIndex
                    continue
                }
                let hex = String(fileName[firstIndex]) + String(fileName[secondIndex])
                if hex == "25" { decoded.append("%") }
                else if hex == "2F" { decoded.append("/") }
                else if hex == "3A" { decoded.append(":") }
                else { decoded.append("%"); decoded.append(contentsOf: hex) }
                index = fileName.index(after: secondIndex)
            } else {
                decoded.append(char)
                index = fileName.index(after: index)
            }
        }
        return NSPasteboard.PasteboardType(decoded.isEmpty ? fileName : decoded)
    }
    
    static func zeroize(_ data: inout Data) {
        guard !data.isEmpty else { return }
        data.withUnsafeMutableBytes { buffer in
            guard let base = buffer.baseAddress else { return }
            memset(base, 0, buffer.count)
        }
    }
}

enum SecureStorageError: LocalizedError {
    case untrustedPath(String)
    case symlinkDetected(String)
    
    var errorDescription: String? {
        switch self {
        case .untrustedPath(let path):
            return "Refusing to use untrusted storage path: \(path)"
        case .symlinkDetected(let path):
            return "Refusing to use symlinked storage path: \(path)"
        }
    }
}
