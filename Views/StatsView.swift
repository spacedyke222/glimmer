import SwiftUI
import Charts

struct StatsView: View {
    
    @State private var selectedPeriod: Int = 3
    let periods = [3, 7, 30]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ShimmerBackground()
                
                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 20)
                    content
                }
            }
        }
    }
}

// MARK: - Header
private extension StatsView {
    
    var header: some View {
        VStack(spacing: 20) {
            Text("STATS")
                .font(.custom("Lato-Black", size: 26))
                .foregroundColor(.white)
                .padding(.top, 20)
            
            Picker("Period", selection: $selectedPeriod) {
                ForEach(periods, id: \.self) { period in
                    Text("\(period)d").tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Content
private extension StatsView {
    
    var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                averageCard
                trendsCard
                recommendationsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30)
                .fill(Color.white.opacity(0.08))
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.2), radius: 12, y: -5)
        }
    }
}

// MARK: - Cards
private extension StatsView {
    
    var averageCard: some View {
        DashboardCard {
            VStack(spacing: 16) {
                
                Text("Average BG per Run")
                    .font(.custom("Lato-Regular", size: 18))
                    .foregroundColor(.white.opacity(0.8))
                
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.purple, Color.cyan],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 8
                        )
                        .frame(width: 140, height: 140)
                    
                    VStack(spacing: 2) {
                        Text("120")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("mg/dL")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    var trendsCard: some View {
        Chart(mockData) { point in
            LineMark(
                x: .value("Day", point.day),
                y: .value("BG", point.value)
            )
            
            AreaMark(
                x: .value("Day", point.day),
                y: .value("BG", point.value)
            )
            .opacity(0.2)
        }
        .frame(height: 140)
        .chartXAxis {
            AxisMarks {
                AxisValueLabel()
                    .foregroundStyle(.white.opacity(0.7))
                
                AxisTick()
                    .foregroundStyle(.white.opacity(0.4))
                
                AxisGridLine()
                    .foregroundStyle(.white.opacity(0.2))
            }
        }

        .chartYAxis {
            AxisMarks {
                AxisValueLabel()
                    .foregroundStyle(.white.opacity(0.7))
                
                AxisTick()
                    .foregroundStyle(.white.opacity(0.4))
                
                AxisGridLine()
                    .foregroundStyle(.white.opacity(0.2))
            }
        }
    }
    
    var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("Recommendations")
                .font(.custom("Lato-Regular", size: 20))
                .foregroundColor(.white)
            
            recommendationCard(
                icon: "leaf.fill",
                text: "Try 5g more carbs before your next run"
            )
            
            recommendationCard(
                icon: "checkmark.circle.fill",
                text: "You're staying in range—keep it up!"
            )
        }
    }
    
    func recommendationCard(icon: String, text: String) -> some View {
        DashboardCard(minHeight: 80) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.green)
                
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


// BG Zone Color System
func colorForBG(_ value: Double) -> Color {
    switch value {
    case ..<80:
        return .red
    case 80...140:
        return .green
    default:
        return .orange
    }
}



// Mark: Example
struct BGPoint: Identifiable {
    let id = UUID()
    let day: String
    let value: Double
}

let mockData: [BGPoint] = [
    .init(day: "Mon", value: 110),
    .init(day: "Tue", value: 125),
    .init(day: "Wed", value: 118),
    .init(day: "Thu", value: 130),
    .init(day: "Fri", value: 122),
    .init(day: "Sat", value: 115),
    .init(day: "Sun", value: 120)
]


#Preview {
    StatsView()
}
