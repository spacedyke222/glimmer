import SwiftUI
import Charts



// MARK: - Models



struct Workout: Identifiable {
    var id = UUID()
    let name: String
    let date: Date
    let duration: TimeInterval
    let distance: Double
    let readings: [BGReading]
    
    var avgPace: Double {
        guard !readings.isEmpty else { return 0 }
        let validPaces = readings.compactMap { $0.pace }
        guard !validPaces.isEmpty else { return 0 }
        return validPaces.reduce(0, +) / Double(validPaces.count)
    }

    var formattedAvgPace: String {
        guard avgPace > 0 else { return "--" }
        return formatPace(avgPace)
    }

    func formatPace(_ pace: Double) -> String {
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d /mi", minutes, seconds)
    }
    
    var avgBG: Double {
        guard !readings.isEmpty else { return 0 }
        return readings.map { $0.value }.reduce(0, +) / Double(readings.count)
    }
    
    var formattedDuration: String {
        let hrs = Int(duration) / 3600
        let mins = (Int(duration) % 3600) / 60
        let secs = Int(duration) % 60
        return hrs > 0 ? String(format: "%d:%02d:%02d", hrs, mins, secs) : String(format: "%02d:%02d", mins, secs)
    }
    
    var formattedDistance: String { String(format: "%.2f mi", distance) }
    var formattedAvgBG: String { String(format: "%.0f mg/dL", avgBG) }
}

// MARK: - Workout History View
struct WorkoutHistoryView: View {
    @EnvironmentObject var workoutStore: WorkoutStore
    @State private var isPressed = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                .ignoresSafeArea()
                
                ShimmerBackground()
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(workoutStore.workouts) { workout in
                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                workoutCard(workout)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
                .background {
                    UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30)
                        .fill(Color.white.opacity(0.08))
                        .ignoresSafeArea(edges: .bottom)
                }
                
                .scrollContentBackground(.hidden)
                .shadow(color: .black.opacity(0.1), radius: 4, y:4)
            }
            .toolbar {
                
                
                // ---- Title ----
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10){
                        Image(systemName: "receipt.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                        Text("Workout History")
                            .font(.custom("Lato-Bold", size: 24))
                            .foregroundStyle(SwiftUI.Color.white)
                    }
                   
                }
            }
        }
    }
}

func workoutCard(_ workout: Workout) -> some View {
    DashboardCard(minHeight: 90) {
        VStack(alignment: .leading, spacing: 10) {
            
            Text(workout.name)
                .font(.custom("Lato-Regular", size: 20))
                .foregroundColor(.white)
            
            Text(workout.date, style: .date)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 16) {
                stat("Avg BG", workout.formattedAvgBG)
                stat("Pace", workout.formattedAvgPace)
                stat("Dist", workout.formattedDistance)
            }
        }
    }
}

func stat(_ label: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
        Text(label)
            .font(.caption2)
            .foregroundColor(.white.opacity(0.6))
        
        Text(value)
            .font(.caption)
            .foregroundColor(.white)
    }
}




// MARK: - Workout Detail View
struct WorkoutDetailView: View {
    let workout: Workout
    @State private var currentReading: BGReading? = nil
    @State private var tooltipX: CGFloat = 0
    
    
    var minBG: Double { workout.readings.map(\.value).min() ?? 0 }
    var maxBG: Double { workout.readings.map(\.value).max() ?? 0 }
    
    var timeInRangePct: Double {
        let countInRange = workout.readings.filter { (70...180).contains($0.value) }.count
        guard !workout.readings.isEmpty else { return 0 }
        return Double(countInRange) / Double(workout.readings.count) * 100
    }
    
    var body: some View {
        
        ZStack{
            
            Color.black.ignoresSafeArea()
            ShimmerBackground()
            
            ScrollView {
                
                VStack(alignment: .leading, spacing: 20) {
                    Text(workout.name)
                        .font(.custom("Lato-Bold", size: 20))
                        .foregroundColor(Color.white)
                    
                    summarySection
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Glucose Over Workout Duration")
                            .font(.custom("Lato-Regular", size: 20))
                            .foregroundColor(.white.opacity(0.8))
                        
                        chartSection
                            .frame(height: 260)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.clear)
                        
                    )
                    
                }
                .padding()
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var summarySection: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 16) {
                
                Text("Summary")
                    .font(.custom("Lato-Regular", size: 20))
                    .foregroundColor(.white)
                
                Grid(horizontalSpacing: 20, verticalSpacing: 15) {
                    GridRow {
                        summaryStat("Avg BG", workout.formattedAvgBG)
                        summaryStat("Min", "\(Int(minBG))")
                        summaryStat("Max", "\(Int(maxBG))")
                    }
                    GridRow {
                        summaryStat("In Range", "\(Int(timeInRangePct))%")
                        summaryStat("Pace", workout.formattedAvgPace)
                        summaryStat("Distance", workout.formattedDistance)
                    }
                }
            }
        }
    }

    private var chartSection: some View {
        let startTime = workout.readings.first?.timestamp ?? workout.date

        return GeometryReader { geo in
            ZStack {
                Chart {
                    ForEach(workout.readings) { reading in
                        
                        LineMark(
                            x: .value("Elapsed", reading.elapsedMinutes(from: startTime)),
                            y: .value("BG", reading.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.purple.opacity(0.6), radius: 4)
                    }
                }
                .chartXScale(domain: 0...max(1, workout.duration / 60))
                .chartYScale(domain: 40...250)

                // 👇 ADD AXIS STYLING RIGHT HERE
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) {
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.15))
                        
                        AxisTick()
                            .foregroundStyle(.white.opacity(0.3))
                        
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.8))
                            .font(.caption)
                    }
                }

                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) {
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.15))
                        
                        AxisTick()
                            .foregroundStyle(.white.opacity(0.3))
                        
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.8))
                            .font(.caption)
                    }
                }
                .chartPlotStyle { plot in
                    plot
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(12)
                }
                
                // Overlay for Tooltip Interaction
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                tooltipX = value.location.x
                                currentReading = nearestReading(x: value.location.x, width: geo.size.width, startTime: startTime)
                            }
                            .onEnded { _ in currentReading = nil }
                    )

                if let reading = currentReading {
                    tooltipView(reading, startTime: startTime)
                        .position(x: tooltipX, y: 50)
                }
            }
        }
    }

    private func summaryStat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.custom("Lato-Regular", size: 14)).foregroundColor(Color.black.opacity(0.8))
            Text(value).font(.custom("Lato-Bold", size: 16)).foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tooltipView(_ reading: BGReading, startTime: Date) -> some View {
        VStack {
            Text("BG: \(Int(reading.value))").bold()
            Text("\(Int(reading.elapsedMinutes(from: startTime))) min")
        }
        .font(.caption2)
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.8)).foregroundColor(.white))
    }

    private func nearestReading(x: CGFloat, width: CGFloat, startTime: Date) -> BGReading? {
        let totalMins = workout.duration / 60
        let targetMins = (x / width) * totalMins
        return workout.readings.min(by: { abs($0.elapsedMinutes(from: startTime) - targetMins) < abs($1.elapsedMinutes(from: startTime) - targetMins) })
    }
}



// MARK: - Previews
#Preview {
    let previewStore = WorkoutStore()
    
    func generateReadings(startDate: Date, count: Int, pace: Double) -> [BGReading] {
        (0..<count).map { i in
            BGReading(
                value: Double.random(in: 80...180),
                trend: ["rising", "falling", "steady"].randomElement() ?? "steady",
                timestamp: startDate.addingTimeInterval(TimeInterval(i * 300)),
                pace: pace
            )
        }
    }
    
    let now = Date()
    
    let mockWorkout3 = Workout(
        name: "Weekend Long Run",
        date: now,
        duration: 5400,
        distance: 10.2,
        readings: generateReadings(startDate: now, count: 18, pace: 9.1)
    )
    
    
    let mockWorkout2 = Workout(
        name: "Evening City Run",
        date: now.addingTimeInterval(-86400),
        duration: 2700,
        distance: 4.0,
        readings: generateReadings(startDate: now.addingTimeInterval(-86400), count: 9, pace: 8.3)
    )
    
    let mockWorkout1 = Workout(
        name: "Morning Trail Run",
        date: now.addingTimeInterval(-86400 * 2),
        duration: 3600,
        distance: 5.5,
        readings: generateReadings(startDate: now.addingTimeInterval(-86400 * 2), count: 12, pace: 7.8)
    )
    
    previewStore.workouts = [mockWorkout3, mockWorkout2, mockWorkout1]
    
    return WorkoutHistoryView()
        .environmentObject(previewStore)
}

