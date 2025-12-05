import SwiftUI

struct NewEntryView: View {
    @StateObject private var viewModel = NewEntryViewModel()
    @Environment(\.dismiss) private var dismiss
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                CandidColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    TextField("Title", text: $viewModel.title)
                        .font(.title2)
                        .padding(20)
                        .background(CandidColors.secondaryBackground)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    TextEditor(text: $viewModel.content)
                        .font(.body)
                        .padding(16)
                        .background(CandidColors.secondaryBackground)
                        .cornerRadius(12)
                        .padding(20)
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
                    if viewModel.isClassifying {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                await viewModel.saveEntry()
                                onSave()
                                dismiss()
                            }
                        }
                        .foregroundColor(CandidColors.text)
                        .disabled(viewModel.title.isEmpty || viewModel.content.isEmpty)
                    }
                }
            }
        }
    }
}
