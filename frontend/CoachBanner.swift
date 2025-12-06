import SwiftUI

struct CoachBanner: View {
    let prompt: String
    let onTap: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundColor(CandidColors.text)
            
            Text(prompt)
                .font(.system(size: CandidTypography.bodySize, weight: CandidTypography.bodyWeight))
                .foregroundColor(CandidColors.text)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(CandidColors.secondaryText)
            }
        }
        .padding(16)
        .background(CandidColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: CandidShadows.card.color, radius: CandidShadows.card.radius, x: CandidShadows.card.x, y: CandidShadows.card.y)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

