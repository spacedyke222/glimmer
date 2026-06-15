import SwiftUI

struct TrendArrowView: View {
    let direction: TrendDirection
    
    var body: some View {
        Image(systemName: systemImageName)
            .font(.system(size: 48, weight: .bold))
            .foregroundColor(.white)
            .shadow(radius: 4)
    }
    
    private var systemImageName: String {
        switch direction {
        case .rising: return "arrow.up"
        case .falling: return "arrow.down"
        case .stable: return "arrow.right"
        }
    }
}
