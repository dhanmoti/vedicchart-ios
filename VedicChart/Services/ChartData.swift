//
//  ChartData.swift
//  VedicChart
//
//  Created by Dhan Moti on 29/1/26.
//


import Foundation
import CoreLocation

struct ChartData: Identifiable, Codable {
    var id = UUID()
    let birthDate: Date
    let locationName: String
    let coordinate: CodableCoordinate
    let ascendantLongitude: Double
    let planetLongitudes: [Planet: Double] // Standardize to this name
    
    var ascendantSignIndex: Int {
        Int(floor(ascendantLongitude / 30.0))
    }
    
    // Add this member to fix the "no member getHouse" error
    func getHouse(for planet: Planet) -> Int {
        guard let lon = planetLongitudes[planet] else { return 1 }
        let planetSignIndex = Int(floor(lon / 30.0))
        return ((planetSignIndex - ascendantSignIndex + 12) % 12) + 1
    }
}
