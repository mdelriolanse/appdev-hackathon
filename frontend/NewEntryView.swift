import SwiftUI
import AudioToolbox

struct NewEntryView: View {
    @StateObject private var viewModel: NewEntryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccessOverlay = false
    @State private var coachBannerTask: Task<Void, Never>?
    let onSave: (JournalEntry?) -> Void
    
    init(title: String = "", body: String = "", onSave: @escaping (JournalEntry?) -> Void) {
        _viewModel = StateObject(wrappedValue: NewEntryViewModel(title: title, body: body))
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                CandidColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    TextField("Entry Title", text: $viewModel.title)
                        .font(.largeTitle.bold()) // Make title distinct
                        .foregroundColor(CandidColors.text)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Coach Banner
                    if let prompt = viewModel.coachPrompt {
                        CoachBanner(prompt: prompt) {
                            viewModel.insertCoachPrompt(prompt)
                            coachBannerTask?.cancel()
                        } onDismiss: {
                            viewModel.dismissCoachPrompt()
                            coachBannerTask?.cancel()
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $viewModel.body)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .padding(20)
                            
                            // Custom placeholder for TextEditor
                            if viewModel.body.isEmpty {
                                Text("Start writing your thoughts here...")
                                    .font(.body)
                                    .foregroundColor(CandidColors.secondaryText.opacity(0.7))
                                    .padding(.horizontal, 24) // Match TextEditor padding
                                    .padding(.vertical, 28)
                                    .allowsHitTesting(false) // Let touches pass through to TextEditor
                            }
                    }
                    .frame(maxHeight: .infinity) // Allow body to expand
                    .onChange(of: viewModel.body) { newValue in
                        viewModel.handleBodyChange(newValue)
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.coachPrompt)
                    
                        if let error = viewModel.error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
                    
                    if let coachError = viewModel.coachError {
                        Text(coachError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
                }
                
                // Floating Coach Button (bottom right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        CoachButton(isLoading: viewModel.isFetchingCoach) {
                            Task {
                                await viewModel.fetchCoachPrompt()
                                
                                // Auto-dismiss after 7 seconds
                                coachBannerTask?.cancel()
                                coachBannerTask = Task {
                                    try? await Task.sleep(nanoseconds: 7_000_000_000)
                                    await MainActor.run {
                                        viewModel.dismissCoachPrompt()
                                    }
                                }
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
                
                // Success Overlay
                if showSuccessOverlay {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(CandidColors.text)
                            .scaleEffect(showSuccessOverlay ? 1.0 : 0.5)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showSuccessOverlay)
                        
                        Text("Saved!")
                            .font(.title2.bold())
                            .foregroundColor(CandidColors.text)
                    }
                    .padding(40)
                    .background(CandidColors.cardBackground)
                    .cornerRadius(20)
                    .shadow(radius: 20)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(CandidColors.text)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                let entry = await viewModel.saveEntry()
                                if entry != nil {
                                    playSuccessSound()
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        showSuccessOverlay = true
                                    }
                                    
                                    // Delay dismissal to show animation
                                    try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds
                                    onSave(entry)
                                    dismiss()
                                }
                            }
                        }
                        .foregroundColor(CandidColors.text)
                        .disabled(viewModel.title.isEmpty || viewModel.body.isEmpty)
                    }
                }
            }
        }
        .onDisappear {
            coachBannerTask?.cancel()
        }
    }
    
    private func playSuccessSound() {
        // System sound 1322 is "Task Completed" / "Payment Success" style
        // 1301 is "Lock"
        // 1322 is generally used for confirmations.
        // Also 1025 (Fanfare) or 1054 (Tri-tone)
        // Trying 1322 for a satisfying task completion sound
        AudioServicesPlaySystemSound(1322) 
    }
}

struct CoachBanner: View {
    let prompt: String
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundColor(.white)
                .font(.system(size: 20))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Candid Coach")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.9))
                
                Text(prompt)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Button(action: onAccept) {
                    Image(systemName: "arrow.turn.down.left")
                        .foregroundColor(CandidColors.text)
                        .padding(6)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .background(CandidColors.buttonBackground)
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

struct CoachButton: View {
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .tint(.white) // White spinner on dark bg
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                }
                Text("Ask Coach")
                    .font(.subheadline.bold())
            }
            .foregroundColor(.white) // White text
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(CandidColors.buttonBackground) // Dark green background
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
        .disabled(isLoading)
    }
}
