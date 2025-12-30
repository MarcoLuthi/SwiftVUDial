//
//  VUDialClient.swift
//  VUDial
//
//  A simple, lightweight client for controlling VU Dials without SwiftData.
//  Perfect for headless applications, scripts, or custom integrations.
//

import Foundation
import AppKit

/// A lightweight client for controlling VU Dials without SwiftData dependency.
///
/// Use this for headless applications, scripts, or when you don't need persistence.
///
/// Example:
/// ```swift
/// let client = VUDialClient()
///
/// if client.connect() {
///     // Set dial to 75%
///     client.setValue(dialIndex: 0, percentage: 75.0)
///
///     // Set red backlight
///     client.setBacklight(dialIndex: 0, red: 100, green: 0, blue: 0)
///
///     // Upload an image
///     if let image = NSImage(named: "gauge") {
///         await client.uploadImage(dialIndex: 0, image: image)
///     }
/// }
/// ```
public class VUDialClient {

    // MARK: - Properties

    private let serialManager: SerialPortManager

    /// Whether the client is connected to a VU Hub
    public var isConnected: Bool {
        serialManager.isConnected
    }

    /// Connection status message
    public var connectionStatus: String {
        serialManager.connectionStatus
    }

    // MARK: - Initialization

    public init() {
        self.serialManager = SerialPortManager()
    }

    // MARK: - Connection

    /// Connect to the VU Hub
    /// - Returns: true if connection successful
    @discardableResult
    public func connect() -> Bool {
        return serialManager.connect()
    }

    /// Disconnect from the VU Hub
    public func disconnect() {
        serialManager.disconnect()
    }

    // MARK: - Dial Control

    /// Set dial value
    /// - Parameters:
    ///   - dialIndex: I2C bus index of the dial (0-7)
    ///   - percentage: Value from 0 to 100
    public func setValue(dialIndex: Int, percentage: Double) {
        let command = VUDialProtocol.setValueCommand(
            dialIndex: UInt8(dialIndex),
            percentage: percentage
        )
        serialManager.sendCommandFireAndForget(command)
    }

    /// Set dial RGB backlight
    /// - Parameters:
    ///   - dialIndex: I2C bus index of the dial (0-7)
    ///   - red: Red channel (0-100)
    ///   - green: Green channel (0-100)
    ///   - blue: Blue channel (0-100)
    public func setBacklight(dialIndex: Int, red: Double, green: Double, blue: Double) {
        let command = VUDialProtocol.setBacklightCommand(
            dialIndex: UInt8(dialIndex),
            red: red,
            green: green,
            blue: blue
        )
        serialManager.sendCommandFireAndForget(command)
    }

    /// Set dial value and backlight in one call
    /// - Parameters:
    ///   - dialIndex: I2C bus index of the dial (0-7)
    ///   - percentage: Value from 0 to 100
    ///   - red: Red channel (0-100)
    ///   - green: Green channel (0-100)
    ///   - blue: Blue channel (0-100)
    public func update(dialIndex: Int, percentage: Double, red: Double, green: Double, blue: Double) {
        setValue(dialIndex: dialIndex, percentage: percentage)
        setBacklight(dialIndex: dialIndex, red: red, green: green, blue: blue)
    }

    // MARK: - Dial Discovery

    /// Rescan I2C bus for dials
    public func rescanBus() {
        let command = VUDialProtocol.rescanBusCommand()
        serialManager.sendCommandFireAndForget(command)
    }

    /// Get UID of dial at specific index
    /// - Parameter dialIndex: I2C bus index (0-7)
    /// - Returns: UID string or nil if no dial found
    public func getDialUID(at dialIndex: Int) async -> String? {
        let command = VUDialProtocol.getUIDCommand(dialIndex: UInt8(dialIndex))

        guard let responseData = await serialManager.sendCommandAsync(command),
              let response = VUDialProtocol.parseResponse(responseData) else {
            return nil
        }

        let uid = response.payloadHexString

        // Skip if UID is all zeros (no dial present)
        guard !uid.isEmpty && uid != "00000000" else {
            return nil
        }

        return uid
    }

    // MARK: - Display

    /// Upload image to dial's e-paper display
    /// - Parameters:
    ///   - dialIndex: I2C bus index of the dial (0-7)
    ///   - image: Image to upload (will be resized to 200x144)
    /// - Returns: true if upload successful
    @discardableResult
    public func uploadImage(dialIndex: Int, image: NSImage) async -> Bool {
        guard let packedData = ImageProcessor.convertImage(image) else {
            print("❌ Failed to process image")
            return false
        }

        let index = UInt8(dialIndex)

        // Clear display
        let clearCommand = VUDialProtocol.displayClearCommand(dialIndex: index, whiteBackground: true)
        serialManager.sendCommandFireAndForget(clearCommand)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Reset cursor
        let gotoCommand = VUDialProtocol.displayGotoXYCommand(dialIndex: index, x: 0, y: 0)
        serialManager.sendCommandFireAndForget(gotoCommand)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Upload in chunks
        let bytesPerColumn = 18
        let columnsPerChunk = 50
        let chunkSize = bytesPerColumn * columnsPerChunk
        let totalChunks = (packedData.count + chunkSize - 1) / chunkSize

        for chunkIndex in 0..<totalChunks {
            let offset = chunkIndex * chunkSize
            let remainingBytes = packedData.count - offset
            let currentChunkSize = min(chunkSize, remainingBytes)

            let chunkData = packedData.subdata(in: offset..<(offset + currentChunkSize))
            let command = VUDialProtocol.displayImageDataCommand(dialIndex: index, data: chunkData)
            serialManager.sendCommandFireAndForget(command)

            try? await Task.sleep(nanoseconds: 250_000_000)
        }

        // Show image
        let showCommand = VUDialProtocol.displayShowImageCommand(dialIndex: index)
        serialManager.sendCommandFireAndForget(showCommand)

        return true
    }

    /// Clear the dial's e-paper display
    /// - Parameters:
    ///   - dialIndex: I2C bus index of the dial (0-7)
    ///   - whiteBackground: true for white, false for black
    public func clearDisplay(dialIndex: Int, whiteBackground: Bool = true) {
        let command = VUDialProtocol.displayClearCommand(
            dialIndex: UInt8(dialIndex),
            whiteBackground: whiteBackground
        )
        serialManager.sendCommandFireAndForget(command)
    }
}
