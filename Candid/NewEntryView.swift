import SwiftUI
import AudioToolbox

struct NewEntryView: View {
    @StateObject private var viewModel: NewEntryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccessOverlay = false
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
                    
                    if let error = viewModel.error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
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
