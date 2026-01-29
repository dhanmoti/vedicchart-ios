//
//  VedicEngine.swift
//  VedicChart
//
//  Created by Dhan Moti on 29/1/26.
//


import Foundation

class VedicEngine {
    static let shared = VedicEngine()
    
    init() {
        // 1. Set the path to the ephemeris binary files (.se1)
        // Ensure these files are in your app bundle's "Resources"
        if let path = Bundle.main.resourcePath {
            swe_set_ephe_path(path)
        }
        
        // 2. Set Sidereal Mode to Lahiri (Standard Vedic)
        swe_set_sid_mode(Int32(SE_SIDM_LAHIRI), 0, 0)
    }

    func generateD1Chart(date: Date, lat: Double, lon: Double) -> ChartData {
        // Convert Swift Date to UTC components
        let calendar = Calendar.current
        let year = Int32(calendar.component(.year, from: date))
        let month = Int32(calendar.component(.month, from: date))
        let day = Int32(calendar.component(.day, from: date))
        
        let hour = Double(calendar.component(.hour, from: date))
        let minute = Double(calendar.component(.minute, from: date))
        let decimalHour = hour + (minute / 60.0)

        // 1) Compute Julian Day (UT)
        var julianDay: Double = 0
        swe_date_conversion(year, month, day, decimalHour, CChar(Int32(SE_GREG_CAL)), &julianDay)

        // 2) Define Flags: Sidereal + Speed (for retrograde info later)
        let flags: Int32 = Int32(SEFLG_SIDEREAL) | Int32(SEFLG_SPEED)

        // 3) Calculate Planet Longitudes
        var positions = [Planet: Double]()
        let planetMap: [Planet: Int32] = [
            .sun: Int32(SE_SUN), .moon: Int32(SE_MOON), .mars: Int32(SE_MARS),
            .mercury: Int32(SE_MERCURY), .jupiter: Int32(SE_JUPITER), 
            .venus: Int32(SE_VENUS), .saturn: Int32(SE_SATURN), .rahu: Int32(SE_MEAN_NODE)
        ]

        var xx = [Double](repeating: 0.0, count: 6)
        var serr = [Int8](repeating: 0, count: 256)

        for (planet, seId) in planetMap {
            swe_calc_ut(julianDay, seId, flags, &xx, &serr)
            positions[planet] = xx[0] // 0 is Longitude
        }

        // 4) Derive Ketu (Rahu + 180)
        if let rahuLon = positions[.rahu] {
            positions[.ketu] = (rahuLon + 180.0).truncatingRemainder(dividingBy: 360.0)
        }

        // 5) Calculate Ascendant (Lagna)
        var cusps = [Double](repeating: 0.0, count: 13)
        var ascmc = [Double](repeating: 0.0, count: 10)
        
        // 'W' = Whole Sign Houses, but we mainly need ascmc[0] for the Ascendant degree
        swe_houses_ex(julianDay, flags, lat, lon, Int32(UnicodeScalar("W").value), &cusps, &ascmc)
        let ascendantLon = ascmc[0]

        return ChartData(
            birthDate: date,
            locationName: "Calculated",
            coordinate: CodableCoordinate(latitude: lat, longitude: lon),
            ascendantLongitude: ascendantLon,
            planetLongitudes: positions
        )
    }
}
