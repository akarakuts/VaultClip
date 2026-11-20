//
//  ClipHotKey.swift
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

class ClipHotKey {
    
    // MARK: - Types
    
    typealias Handler = () -> Void
    
    // MARK: - Public attributes
    
    /// When true, the underlying Carbon hot key is not registered.
    var isPaused: Bool {
        get { _isPaused }
        set {
            _isPaused = newValue
            if newValue {
                _hotKey?.isPaused = true
            } else {
                ensureRegistered()
                _hotKey?.isPaused = false
            }
        }
    }
    
    var longPressStartingInterval: TimeInterval = 0.4
    var longPressMinInterval: TimeInterval = 0.1
    var longPressAcceleration: TimeInterval = 2

    /// Exposed for unit tests that simulate key events on the underlying HotKey.
    var hotKey: HotKey {
        ensureRegistered()
        return _hotKey!
    }
    
    // MARK: - Private attributes
    
    private var keyCombo: KeyCombo
    private var _hotKey: HotKey?
    private var _isPaused: Bool
    
    private var keyDownObservers = [Handler]()
    private var keyUpObservers = [Handler]()
    private var longPressObservers = [Handler]()
    private var longPressTimer: Timer?
    
    // MARK: - Constructors
    
    init(hotKey: HotKey) {
        self.keyCombo = hotKey.keyCombo
        self._hotKey = hotKey
        self._isPaused = hotKey.isPaused
        wireHandlers(on: hotKey)
    }
    
    /// Creates a hot key that stays unregistered until `isPaused` becomes false (default).
    convenience init(key: Key, modifiers: NSEvent.ModifierFlags, startsPaused: Bool = true) {
        self.init(keyCombo: KeyCombo(key: key, modifiers: modifiers), startsPaused: startsPaused)
    }

    init(keyCombo: KeyCombo, startsPaused: Bool = true) {
        self.keyCombo = keyCombo
        self._isPaused = startsPaused
        if !startsPaused {
            ensureRegistered()
        }
    }
    
    // MARK: - Public Methods
    
    func onDown(_ obv: @escaping Handler) {
        keyDownObservers.append(obv)
    }
    
    func onUp(_ obv: @escaping Handler) {
        keyUpObservers.append(obv)
    }
    
    func onLong(_ obv: @escaping Handler) {
        longPressObservers.append(obv)
    }
    
    func changeHotKey(keyCombo: KeyCombo) {
        _hotKey?.isPaused = true
        _hotKey = nil
        self.keyCombo = keyCombo
        if !_isPaused {
            ensureRegistered()
        }
    }
    
    func simulateOnDown() {
        for obv in self.keyDownObservers {
            obv()
        }
    }
    
    // MARK: - Private Methods

    private func ensureRegistered() {
        if _hotKey != nil { return }
        let created = HotKey(keyCombo: keyCombo)
        wireHandlers(on: created)
        created.isPaused = _isPaused
        _hotKey = created
    }

    private func wireHandlers(on hotKey: HotKey) {
        hotKey.keyDownHandler = { [weak self] in
            guard let self else { return }
            for obv in self.keyDownObservers {
                obv()
            }
            self.stopLongPressTimer()
            self.setLongPressTimer(withInterval: self.longPressStartingInterval)
        }
        hotKey.keyUpHandler = { [weak self] in
            guard let self else { return }
            for obv in self.keyUpObservers {
                obv()
            }
            self.stopLongPressTimer()
        }
    }
    
    private func stopLongPressTimer() {
        if let timer = longPressTimer {
            timer.invalidate()
            self.longPressTimer = nil
        }
    }
    
    private func setLongPressTimer(withInterval interval: TimeInterval) {
        self.longPressTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false, block: { [weak self] _ in
            guard let self else { return }
            for obv in self.longPressObservers {
                obv()
            }
            let nextInterval = max(self.longPressMinInterval, interval / self.longPressAcceleration)
            self.setLongPressTimer(withInterval: nextInterval)
        })
    }
}
