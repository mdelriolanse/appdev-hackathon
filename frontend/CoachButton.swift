import SwiftUI

struct CoachButton: View {
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 20))
            }
        }
        .foregroundColor(CandidColors.text)
        .disabled(isLoading)
    }
}

