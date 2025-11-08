//
//  Item.swift
//  VUDial
//
//  Created by Marco Luthi on 08.11.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
