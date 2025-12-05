import SwiftUI

struct NewEntryView: View {
    @StateObject private var viewModel: NewEntryViewModel
    @Environment(\.dismiss) private var dismiss
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
                    
                    if let error = viewModel.error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
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
                                onSave(entry)
                                dismiss()
                            }
                        }
                        .foregroundColor(CandidColors.text)
                        .disabled(viewModel.title.isEmpty || viewModel.body.isEmpty)
                    }
                }
            }
        }
    }
}
