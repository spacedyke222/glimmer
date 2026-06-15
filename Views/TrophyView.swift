//
//  TrophyView.swift
//  TRunD
//
//  Created by Lauren Harrell on 11/29/25.
//

import SwiftUI

struct TrophyView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ShimmerBackground()

            Text("Badges & Awards")
                .font(.largeTitle).bold()
                .foregroundColor(.white)
        }
    }
}
#Preview {
    TrophyView()
}
