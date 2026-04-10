//
//  BadgesView.swift
//  TRunD
//
//  Created by Bitch Bag 1 on 11/29/25.
//

import SwiftUI


struct Badge: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String // SF Symbol or custom asset
    let color: Color
    let isUnlocked: Bool // New property
}


struct BadgesView: View {
    let badges: [Badge] = [
        Badge(name: "Marathoner", description: "Furthest distance run", icon: "figure.run", color: .orange, isUnlocked: true),
        Badge(name: "Master of Control", description: "Stayed in range for 5 consecutive runs", icon: "shield.checkerboard", color: .purple, isUnlocked: false),
        Badge(name: "Consistency Queen", description: "Worked out 5 days a week", icon: "calendar.circle.fill", color: .green, isUnlocked: true),
        Badge(name: "Early Bird", description: "Completed morning runs 7 days in a row", icon: "sunrise.fill", color: .yellow, isUnlocked: false),
        Badge(name: "Night Owl", description: "Completed evening runs 7 days in a row", icon: "moon.fill", color: .blue, isUnlocked: true),
        Badge(name: "Hydration Hero", description: "Drank enough water for a week", icon: "drop.fill", color: .cyan, isUnlocked: false),
        Badge(name: "Speedster", description: "Fastest 5k time", icon: "bolt.fill", color: .pink, isUnlocked: true)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                Text("Your Achievements")
                    .foregroundColor(Color.indigo)
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 40)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(badges) { badge in
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(badge.isUnlocked ? Color.indigo.opacity(0.8) : Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: badge.isUnlocked ? "trophy.fill" : "lock.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(badge.isUnlocked ? Color.yellow : Color.gray)
                            }
                            
                            Text(badge.name)
                                .font(.headline)
                                .foregroundColor(badge.isUnlocked ? Color.indigo : Color.gray)
                            
                            Text(badge.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(width: 170, height: 200) // uniform card size
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.purple.opacity(0.2))
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
        .navigationTitle("Badges & Achievements")
    }
}

#Preview {
    BadgesView()
}
