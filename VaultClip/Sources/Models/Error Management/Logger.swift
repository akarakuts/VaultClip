//
//  Logger.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class Logger {

    var url: URL
    private let queue = DispatchQueue(label: "VaultClip.Logger")
    private var writesSinceRotationCheck = 0

    init(url: URL) {
        self.url = url
    }

    func logLine(_ message: String) {
        let timestamp = Timestamp()
        let line = "[\(timestamp)] \(message)"
        queue.async {
            do {
                try line.appendLine(toURL: self.url)
                self.checkRotationIfNeeded()
            } catch {
                #if DEBUG
                print("Failed to log:", message)
                #endif
            }
        }
        #if DEBUG
        print("[\(timestamp)]", message)
        #endif
    }

    func log(_ loggable: Loggable) {
        let timestamp = Timestamp()
        let line = "[\(timestamp)] \(loggable.logFileDescription)"
        queue.async {
            do {
                try line.appendLine(toURL: self.url)
                self.checkRotationIfNeeded()
            } catch {
                #if DEBUG
                print("Failed to log:")
                #endif
            }
        }
        #if DEBUG
        print("[\(timestamp)]", loggable.consoleDescription)
        #endif
    }

    private func checkRotationIfNeeded() {
        writesSinceRotationCheck += 1
        guard writesSinceRotationCheck >= 100 else { return }
        writesSinceRotationCheck = 0
        LogStorage.rotateIfNeeded(at: url)
    }
}

// https://stackoverflow.com/a/40687742
extension String {
   func appendLine(toURL url: URL) throws {
        try (self + "\n").append(toURL: url)
    }

    func append(toURL url: URL) throws {
        guard let data = self.data(using: String.Encoding.utf8) else { return }
        try data.append(fileURL: url)
    }
}

extension Data {
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            var isDirectory: ObjCBool = false
            let directory = fileURL.deletingLastPathComponent()

            if !FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            } else if !isDirectory.boolValue {
                try FileManager.default.removeItem(at: directory)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            LogStorage.ensureLogFileExists(at: fileURL)
            if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
                defer { fileHandle.closeFile() }
                fileHandle.seekToEndOfFile()
                fileHandle.write(self)
            } else {
                try write(to: fileURL, options: .atomic)
                try? FileManager.default.setAttributes(
                    [.posixPermissions: NSNumber(value: LogStorage.logFilePermissions)],
                    ofItemAtPath: fileURL.path
                )
            }
        }
    }
}

/// https://stackoverflow.com/a/51198997
class Timestamp: CustomStringConvertible {

    var date: Date

    init(date: Date = Date()) {
        self.date = date
    }

    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    var description: String {
        return Self.dateFormatter.string(from: date)
    }
}
