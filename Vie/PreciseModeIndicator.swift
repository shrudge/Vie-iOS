import SwiftUI

struct PreciseModeIndicator: View {
    var body: some View {
        Rectangle()
            .stroke(Color.white, lineWidth: 2)
            .frame(width: 20, height: 20)
            .background(Color.black.opacity(0.2))
            .shadow(color: .black.opacity(0.5), radius: 1)
    }
} 