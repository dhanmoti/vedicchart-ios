//
//  VedicTestView.swift
//  VedicChart
//
//  Created by Dhan Moti on 29/1/26.
//


import SwiftUI

struct VedicTestView: View {
    @State private var output: String = "Press 'Run Test' to calculate..."
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Vedic Engine Diagnostic")
                    .font(.title).bold()
                
                Button("Run Calculation Test") {
                    runDiagnostic()
                }
                .buttonStyle(.borderedProminent)
                
                Divider()
                
                Text(output)
                    .font(.system(.body, design: .monospaced))
            }
            .padding()
        }
    }
    
    func runDiagnostic() {
        let engine = VedicEngine.shared
        let rangoonTimeZone = TimeZone(secondsFromGMT: 6 * 3600 + 1800) ?? .current
        let input = BirthInput(
            year: 1991,
            month: 11,
            day: 13,
            hour: 15,
            minute: 0,
            second: 0,
            timeZone: rangoonTimeZone,
            latitude: 16.8409,
            longitude: 96.1735,
            locationName: "Rangoon, Burma"
        )
        let chart = engine.generateD1Chart(input: input)
        
        var report = "--- RESULTS ---\n"
        report += "Location: \(chart.locationName)\n"
        report += "Ascendant: \(String(format: "%.2f", chart.ascendantLongitude))°\n"
        report += "Asc Sign: \(chart.ascendantSignIndex) (0=Aries)\n\n"
        
        report += "Planet      | Deg        | House\n"
        report += "-------------------------------\n"
        
        for planet in Planet.allCases {
            let lon = chart.planetLongitudes[planet] ?? 0
            let house = chart.getHouse(for: planet)
            
            // Use %@ for Swift Strings to avoid format specifier mismatches
            report += String(format: "%-11@ | %-10.2f | %-5d\n", planet.rawValue, lon, house)
        }
        
        self.output = report
    }
}
