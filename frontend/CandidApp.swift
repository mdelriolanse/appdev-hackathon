import SwiftUI

@main
struct CandidApp: App {
    @State private var dailyQuote = DailyQuote.getTodaysQuote()
    @State private var showQuote = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                
                if showQuote {
                    VStack {
                        Spacer()
                        DailyQuoteBanner(quote: dailyQuote) {
                            withAnimation {
                                showQuote = false
                            }
                        }
                        .padding(.bottom, 90)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
    }
}

struct DailyQuoteBanner: View {
    let quote: String
    let onDismiss: () -> Void
    
    var body: some View {
        Text(quote)
            .font(.callout)
            .foregroundColor(CandidColors.text)
            .multilineTextAlignment(.center)
            .padding(16)
            .background(CandidColors.secondaryBackground.opacity(0.95))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .onTapGesture {
                onDismiss()
            }
    }
}
