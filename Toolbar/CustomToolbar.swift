//
//  CustomToolbar.swift
//  TRunD
//
//  Created by Bitch Bag 1 on 11/29/25.
//

import SwiftUI

struct CustomToolbar: View {
    @Binding var selectedTab: Tab
    

    var body: some View {
        VStack {
            Spacer()   // pushes toolbar to bottom

            HStack(spacing: 30) {

                // HOME
                VStack {
                    Image(systemName: "house.fill")
                        .font(.system(size: 26))
                        .foregroundColor(selectedTab == .home ? Color.white : .gray)
                    Text("Home")
                        .font(.caption2)
                        .foregroundColor(selectedTab == .home ? Color.white : .gray)
                }
                .onTapGesture { selectedTab = .home }

                // STATS
                VStack {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 26))
                        .foregroundColor(selectedTab == .stats ? Color.white : .gray)
                    Text("Stats")
                        .font(.caption2)
                        .foregroundColor(selectedTab == .stats ? Color.white : .gray)
                }
                .onTapGesture { selectedTab = .stats }

                // RECORD
                VStack {
                    Image(systemName: "record.circle")
                        .font(.system(size: 32))
                        .foregroundColor(selectedTab == .activity ? Color.white: .gray)
                    Text("Record")
                        .font(.caption2)
                        .foregroundColor(selectedTab == .activity ? Color.white : .gray)
                }
                .onTapGesture { selectedTab = .activity }

                // PROFILE
                VStack {
                    Image(systemName: "person.fill")
                        .font(.system(size: 26))
                        .foregroundColor(selectedTab == .profile ? Color.white : .gray)
                    Text("Profile")
                        .font(.caption2)
                        .foregroundColor(selectedTab == .profile ? Color.white : .gray)
                }
                .onTapGesture { selectedTab = .profile }

                // SETTINGS
                VStack {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 26))
                        .foregroundColor(selectedTab == .settings ? Color.white : .gray)
                    Text("Settings")
                        .font(.caption2)
                        .foregroundColor(selectedTab == .settings ? Color.white : .gray)
                }
                .onTapGesture { selectedTab = .settings }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: 100)
            .background(
                Rectangle()
                    .fill(Color.black)
            )
            .padding(.horizontal, 0)
            .padding(.bottom, 0)
        }
        .ignoresSafeArea(edges: .bottom)  // extend edge-to-edge
    }

}

struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}


#Preview {
    // Use a State variable to provide a binding
    StatefulPreviewWrapper(Tab.home) { binding in
        CustomToolbar(selectedTab: binding)
    }
}

