//
//  PasswordCommentPrompt.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa

struct PasswordEntryFields {
    let comment: String
    let login: String
    let url: String
}

enum PasswordEntryPrompt {
    
    /// Returns trimmed fields on Save, nil on Cancel.
    static func run(
        title: String,
        message: String,
        initialComment: String = "",
        initialLogin: String = "",
        initialURL: String = ""
    ) -> PasswordEntryFields? {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: L10n.commonSave)
        alert.addButton(withTitle: L10n.commonCancel)
        
        let commentField = NSTextField(frame: NSRect(x: 0, y: 56, width: 280, height: 24))
        commentField.stringValue = initialComment
        commentField.placeholderString = L10n.passwordFieldComment
        
        let loginField = NSTextField(frame: NSRect(x: 0, y: 28, width: 280, height: 24))
        loginField.stringValue = initialLogin
        loginField.placeholderString = L10n.passwordFieldLogin
        
        let urlField = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        urlField.stringValue = initialURL
        urlField.placeholderString = L10n.passwordFieldURL
        
        let stack = NSStackView(frame: NSRect(x: 0, y: 0, width: 280, height: 84))
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.addArrangedSubview(commentField)
        stack.addArrangedSubview(loginField)
        stack.addArrangedSubview(urlField)
        alert.accessoryView = stack
        
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return PasswordEntryFields(
            comment: commentField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
            login: loginField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
            url: urlField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
