//
//  Planet.swift
//  VedicChart
//
//  Created by Dhan Moti on 29/1/26.
//


import Foundation

enum Planet: String, CaseIterable, Codable, Identifiable {
    case sun = "Sun", moon = "Moon", mars = "Mars", mercury = "Mercury"
    case jupiter = "Jupiter", venus = "Venus", saturn = "Saturn", rahu = "Rahu", ketu = "Ketu"
    
    var id: String { self.rawValue }
}
