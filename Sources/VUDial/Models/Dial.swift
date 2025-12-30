//
//  Dial.swift
//  VUDial
//
//  Created by Claude Code on 08.11.2025.
//

import Foundation
import SwiftData

@Model
final public class Dial {
    // MARK: - Identity

    /// Unique hardware identifier (from device)
    public var uid: String

    /// User-friendly name
    public var name: String

    /// Position on I2C bus (0-N)
    public var index: Int

    // MARK: - State

    /// Current dial value (0-100%)
    public var currentValue: Double

    /// Red backlight channel (0-100%)
    public var red: Double

    /// Green backlight channel (0-100%)
    public var green: Double

    /// Blue backlight channel (0-100%)
    public var blue: Double

    /// Last communication timestamp
    public var lastSeen: Date

    /// Is dial currently reachable
    public var isOnline: Bool

    // MARK: - Image

    /// Current image data (1-bit packed, 6000 bytes)
    public var imageData: Data?

    /// Image thumbnail for preview
    public var imageThumbnail: Data?

    // MARK: - Initialization

    public init(
        uid: String,
        name: String,
        index: Int,
        currentValue: Double = 0,
        red: Double = 0,
        green: Double = 0,
        blue: Double = 0
    ) {
        self.uid = uid
        self.name = name
        self.index = index
        self.currentValue = currentValue
        self.red = red
        self.green = green
        self.blue = blue
        self.lastSeen = Date()
        self.isOnline = false
        self.imageData = nil
        self.imageThumbnail = nil
    }

    // MARK: - Convenience

    /// Update backlight colors
    public func setBacklight(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// Update dial value
    public func setValue(_ value: Double) {
        self.currentValue = max(0, min(100, value))
    }

    /// Mark as seen (online)
    public func markSeen() {
        self.lastSeen = Date()
        self.isOnline = true
    }

    /// Mark as offline
    public func markOffline() {
        self.isOnline = false
    }
}
