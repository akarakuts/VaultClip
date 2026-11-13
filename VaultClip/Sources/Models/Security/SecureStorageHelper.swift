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
    
    /// Characters kept verbatim in stored filenames. Everything else (including `%`, `/`, `:`)
    /// becomes `%XX` so encode/decode is a lossless round-trip and no raw type can escape the item directory.
    private static let unreservedFilenameCharacters: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: ".-_")
        return set
    }()

    static func sanitizedPasteboardFileName(for type: NSPasteboard.PasteboardType) -> String {
        let raw = type.rawValue
        // "." and ".." must never become a stored path component.
        if !raw.isEmpty && raw.allSatisfy({ $0 == "." }) {
            return raw.unicodeScalars.map { String(format: "%%%02X", $0.value) }.joined()
        }
        return raw.addingPercentEncoding(withAllowedCharacters: unreservedFilenameCharacters) ?? raw
    }

    static func pasteboardType(fromStoredFileName fileName: String) -> NSPasteboard.PasteboardType {
        var decoded = ""
        var index = fileName.startIndex
        while index < fileName.endIndex {
            let char = fileName[index]
            if char == "%" {
                let firstIndex = fileName.index(after: index)
                let secondIndex = firstIndex < fileName.endIndex ? fileName.index(after: firstIndex) : firstIndex
                if firstIndex < fileName.endIndex, secondIndex < fileName.endIndex,
                   let byte = UInt8(String(fileName[firstIndex...secondIndex].uppercased()), radix: 16) {
                    // A decoded NUL byte can never be part of a pasteboard type — drop it.
                    if byte > 0 { decoded.append(Character(UnicodeScalar(byte))) }
                    index = fileName.index(after: secondIndex)
                    continue
                }
                decoded.append("%")
                index = firstIndex
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
