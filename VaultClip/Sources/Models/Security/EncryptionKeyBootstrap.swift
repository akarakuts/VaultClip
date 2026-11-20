//
// EncryptionKeyBootstrap — launch-time key load with NSAlert recovery UI (T39).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa
import Foundation
import Security

enum EncryptionKeyBootstrap {

    private static var didPrepare = false

    static func prepareAtLaunch() {
        guard !didPrepare else { return }
        didPrepare = true
        do {
            _ = try SymmetricKeyStore.default.loadOrCreateKey()
        } catch SymmetricKeyStoreError.keyMismatch {
            showKeyMismatchAlert()
        } catch KeychainSymmetricKeyStore.KeychainError.osStatus(let status) {
            showKeychainFatalAlert(status: status)
        } catch {
            showFatalAlert(error)
        }
    }

    private static func showKeyMismatchAlert() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.encryptionDecryptTitle
        alert.informativeText = L10n.encryptionDecryptBody
        alert.addButton(withTitle: L10n.commonStartFresh)
        alert.addButton(withTitle: L10n.commonQuit)
        if alert.runModal() == .alertFirstButtonReturn {
            do {
                SymmetricKeyStore.clearCachedKey()
                try SymmetricKeyStore.default.resetEncryptedHistoryAndCreateNewKey()
                _ = try SymmetricKeyStore.default.loadOrCreateKey()
            } catch {
                showFatalAlert(error)
            }
            return
        }
        NSApp.terminate(nil)
    }

    private static func showKeychainFatalAlert(status: OSStatus) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = L10n.encryptionKeyTitle
        alert.informativeText = keychainErrorMessage(for: status)
        alert.addButton(withTitle: L10n.commonOpenKeychainAccess)
        alert.addButton(withTitle: L10n.commonQuit)
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Utilities/Keychain Access.app"))
        }
        NSApp.terminate(nil)
    }

    private static func showFatalAlert(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = L10n.encryptionKeyTitle
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: L10n.commonQuit)
        alert.runModal()
        NSApp.terminate(nil)
    }

    private static func keychainErrorMessage(for status: OSStatus) -> String {
        let account = KeychainSymmetricKeyStore.default.account
        if status == errSecInteractionNotAllowed {
            return L10n.encryptionKeychainUnlock
        }
        if status == errSecAuthFailed {
            return L10n.encryptionKeychainDenied(account: account)
        }
        if status == errSecMissingEntitlement {
            return L10n.encryptionKeychainEntitlement(status: status)
        }
        return L10n.encryptionKeychainGeneric(status: status)
    }
}
