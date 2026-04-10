//
//  WorkoutAdvisor.swift
//  TRunD
//
//  Created by Bitch Bag 1 on 11/24/25.
//

struct WorkoutAdvice {
    let message: String
    let action: String?
}

class WorkoutAdvisor {
    func advice(for reading: BGReading) -> WorkoutAdvice {
        if reading.value < 90 {
            return WorkoutAdvice(message: "BG low", action: "Take 10–15g carbs")
        } else if reading.value > 250 {
            return WorkoutAdvice(message: "BG high", action: "Wait before running")
        } else {
            return WorkoutAdvice(message: "Safe to run!", action: nil)
        }
    }
}
