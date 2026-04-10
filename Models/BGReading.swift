//
//  BGReading.swift
//  TRunD
//
//  Created by Lo on 11/24/25.
//

import Foundation

struct BGReading: Identifiable, Codable {
    var id = UUID()
    let value: Double
    let trend: String
    let timestamp: Date
    let pace: Double? // pace in min/km or min/mi
    
    // Returns pace as "mm:ss" string
        var formattedPace: String? {
            guard let pace = pace else { return nil }
            let minutes = Int(pace)
            let seconds = Int((pace - Double(minutes)) * 60)
            return String(format: "%d:%02d /mi", minutes, seconds)
        }
}

extension BGReading {
    func elapsedMinutes(from start: Date) -> Double {
        timestamp.timeIntervalSince(start) / 60
    }
}

extension LiveReading {
    func toBGReading() -> BGReading {
        BGReading(
            value: bg,
            trend: "steady",          // you can refine later
            timestamp: timestamp,
            pace: nil
        )
    }
}
