//
//  KeyPressMonitor.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa
import HotKey

class KeyPressMonitor {
    
    var keyUpMonitor: EventMonitor!
    var keyDownMonitor: EventMonitor!
    var specialKeyMonitor: SpecialKeyChangedEventMonitor!
    
    var allowedModifierFlags: NSEvent.ModifierFlags
    
    var keysDown = Set<Key>()
    var modifiers: NSEvent.ModifierFlags = .init()
    
    var keyActionHandlers = Set<KeyActionHandler>()
    
    typealias KeyDownHandler = ([Key], NSEvent.ModifierFlags) -> Void
    
    var keyDownHandlers = [KeyDownHandler]()
    
    var isPaused: Bool = true {
        didSet {
            keyUpMonitor.isActive = !isPaused
            keyDownMonitor.isActive = !isPaused
            specialKeyMonitor.isActive = !isPaused
        }
    }
    
    init(allowedModifierFlags: NSEvent.ModifierFlags = NSEvent.ModifierFlags.recommended) {
        self.allowedModifierFlags = allowedModifierFlags
        self.keyUpMonitor = KeyUpEventMonitor(handler: onKeyUp)
        self.keyDownMonitor = KeyDownEventMonitor(handler: onKeyDown)
        self.specialKeyMonitor = SpecialKeyChangedEventMonitor(handler: onSpecialKeyChange)
    }
    
    func handleAction(_ action: KeyAction, forKey key: Key, withModifiers modifiers: NSEvent.ModifierFlags, isExclusive: Bool = false, handler: @escaping () -> Void) {
        // TODO
        #if DEBUG
        if !modifiers.isSubset(of: allowedModifierFlags) {
            print("Warning: Action handler [action=\(action), key='\(key)'] contains not allowed modifier flags. They will be automatically removed.")
        }
        #endif
        
        let keyActionHandler = KeyActionHandler(action: action, key: key, modifiers: modifiers.intersection(allowedModifierFlags), isExclusive: isExclusive, handler: handler)
        
        if keyActionHandlers.remove(keyActionHandler) != nil {
            #if DEBUG
            print("Already contained a handler for that key action. Removed and replaced")
            #endif
        }
        keyActionHandlers.insert(keyActionHandler)
    }
    
    func subscribeToKeyDown(_ handler: @escaping KeyDownHandler) {
        keyDownHandlers.append(handler)
    }
    
    private func checkKeyUpHandlers(forKey key: Key) {
        if let handler = keyActionHandlers.filter({ $0.key == key && $0.action == .up && $0.modifiers.equals(modifiers) }).first {
            handler.handler()
        }
    }
    
    private func checkKeyDownHandlers(forKey key: Key) {
        if let handler = keyActionHandlers.filter({ $0.key == key && $0.action == .down && $0.modifiers.equals(modifiers) }).first {
            handler.handler()
        }
    }
    
    private func checkHandlers(forKey key: Key, withAction action: KeyAction) {
        // Key Up
        if action == .up {
            checkKeyUpHandlers(forKey: key)
        }
        
        // Key down
        if action == .down {
            checkKeyDownHandlers(forKey: key)
        }
    }
    
    private func keyUp(_ key: Key) {
        #if DEBUG
        print("Key '\(key)' up")
        #endif
        _ = keysDown.remove(key)
        checkHandlers(forKey: key, withAction: .up)
    }
    
    private func keyDown(_ key: Key) {
        #if DEBUG
        print("Key '\(key)' down")
        #endif
        keysDown.insert(key)
        checkHandlers(forKey: key, withAction: .down)
        keyDownHandlers.forEach { $0(self.keysDown.map{$0}, self.modifiers) }
    }
    
    private func onSpecialKeyChange(_ event: NSEvent) {
        // TODO
        /*
         if let key = Key(carbonKeyCode: UInt32(event.keyCode)) {
         let modifier = NSEvent.ModifierFlags(carbonFlags: UInt32(event.keyCode))
         
         //            NSEvent.ModifierFlags.init(rawValue: 0).
         if !event.modifierFlags.contains(modifier) {
         print("\(modifier) up")
         } else {
         print("\(modifier) down")
         }
         }
         */
    }
    
    private func onKeyUp(_ event: NSEvent) {
        modifiers = event.modifierFlags.intersection(allowedModifierFlags)
        if let key = Key(carbonKeyCode: UInt32(event.keyCode)) {
            keyUp(key)
        } else {
            debugLogUnknownKeyCode(event.keyCode)
        }
    }
    
    private func onKeyDown(_ event: NSEvent) {
        modifiers = event.modifierFlags.intersection(allowedModifierFlags)
        if let key = Key(carbonKeyCode: UInt32(event.keyCode)) {
            keyDown(key)
        } else {
            debugLogUnknownKeyCode(event.keyCode)
        }
    }
    
    private func debugLogUnknownKeyCode(_ keyCode: UInt16) {
        #if DEBUG
        print("Could not create Key enum with keyCode: \(keyCode)")
        #endif
    }
}
