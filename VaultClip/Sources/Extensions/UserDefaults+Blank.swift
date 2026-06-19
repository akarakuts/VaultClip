//
//  UserDefaults+Blank.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

extension UserDefaults {

    private static var defaultPersistentDomainName: String {
        Bundle.main.bundleIdentifier ?? "VaultClip.UserDefaults.Blank"
    }
    
    /**
     Allows execution of the handler with a fresh user defaults. Designed for testing.
     
     Adapted from: [http://www.figure.ink/blog/2016/10/15/testing-userdefaults](http://www.figure.ink/blog/2016/10/15/testing-userdefaults)
     
     - Parameter handler: Code to execute under a clean user defaults.
     */
    func blankWhile(handler: @escaping () -> Void) {
        let name = Self.defaultPersistentDomainName
        let old = self.persistentDomain(forName: name)
        defer {
            self.setPersistentDomain(old ?? [:], forName: name)
        }
        
        self.removePersistentDomain(forName: name)
        handler()
    }
    
    /**
     Blanks a user defaults until it is restored again.
     
     - Returns: A dictionary of the original content of the user defaults. This should be passed to `restore(:)` to restore the user defaults back to normal.
     */
    func blank() -> [String: Any] {
        let name = Self.defaultPersistentDomainName
        let old = self.persistentDomain(forName: name)
        self.removePersistentDomain(forName: name)
        return old ?? [:]
    }
    
    /**
     Restores a user defaults from a given dictionary.
     
     - Parameter old: A dictionary of the original content of the user defaults. This should be the dictionary returned from `blank()` to restore the user defaults back to normal.
     */
    func restore(from old: [String: Any]) {
        self.setPersistentDomain(old, forName: Self.defaultPersistentDomainName)
    }
    
    /**
     Blanks a user defaults domain until it is restored again.
     
     - Returns: A dictionary of the original content of the user defaults. This should be passed to `restore(:)` to restore the user defaults back to normal.
     - Parameter name: The name of the domain whose contents you want to set.
     */
    func blank(forName name: String) -> [String: Any] {
        let old = self.persistentDomain(forName: name)
        self.removePersistentDomain(forName: name)
        return old ?? [:]
    }
    
    /**
     Restores a user defaults persistent domain of given name from a given dictionary.
     
     - Parameter old: A dictionary of the original content of the user defaults. This should be the dictionary returned from `blank()` to restore the user defaults back to normal.
     - Parameter name: The name of the domain whose contents you want to set.
     */
    func restore(from old: [String: Any], forName name: String) {
        self.setPersistentDomain(old, forName: name)
    }
}
