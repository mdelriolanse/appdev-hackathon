import SwiftUI

@main
struct CandidApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @State private var dailyQuote = DailyQuote.getTodaysQuote()
    @State private var showQuote = true
    
    var body: some View {
        ZStack {
            // Main app content
            MainTabView()
            
            // Quote overlay
            if showQuote {
                FullScreenQuoteView(quote: dailyQuote) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        showQuote = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}

struct FullScreenQuoteView: View {
    let quote: String
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            CandidColors.background.ignoresSafeArea()
            
            VStack {
                Spacer()
                Text(quote)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(CandidColors.text)
                    .multilineTextAlignment(.center)
                    .padding(32)
                Spacer()
                Text("Tap to continue")
                    .font(.caption)
                    .foregroundColor(CandidColors.secondaryText)
                    .padding(.bottom, 50)
            }
        }
        .contentShape(Rectangle()) // Make entire screen tappable
        .onTapGesture {
            onDismiss()
        }
    }
}
