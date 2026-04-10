import SwiftUI

enum TrendDirection {
    case stable
    case rising
    case falling
}

func trendSymbol(for direction: TrendDirection) -> String {
    switch direction {
    case .stable:  return "arrow.right"
    case .rising:  return "arrow.up"
    case .falling: return "arrow.down"
    }
}

func trendColor(for direction: TrendDirection) -> Color {
    switch direction {
    case .stable:  return .gray
    case .rising:  return .green
    case .falling: return .red
    }
}

func convertTrend(_ trend: String) -> TrendDirection {
    switch trend.lowercased() {
    case "up", "↑":
        return .rising
    case "down", "↓":
        return .falling
    default:
        return .stable
    }
}

