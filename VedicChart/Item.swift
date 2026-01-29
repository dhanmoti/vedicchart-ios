//
//  Item.swift
//  VedicChart
//
//  Created by Dhan Moti on 29/1/26.
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
