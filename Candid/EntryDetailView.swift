import SwiftUI
import UIKit

struct EntryDetailView: View {
    @StateObject private var viewModel: EntryDetailViewModel
    @State private var showingFactCheckResult = false
    
    init(entry: JournalEntry) {
        _viewModel = StateObject(wrappedValue: EntryDetailViewModel(entry: entry))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                content
                evidenceSection
                factCheckResultsSection
            }
            .padding(20)
        }
        .background(CandidColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isFactChecking {
                    ProgressView()
                }
            }
        }
        .task {
            await viewModel.loadEvidence()
        }
        .sheet(isPresented: $showingFactCheckResult) {
            if let result = viewModel.lastFactCheckResult {
                FactCheckResultView(result: result)
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.entry.title)
                .font(.title.bold())
                .foregroundColor(CandidColors.text)
            
            HStack {
                Text(viewModel.entry.date, style: .date)
                    .font(.callout)
                    .foregroundColor(CandidColors.secondaryText)
                
                Spacer()
                
                // Display categories
                ForEach(viewModel.entry.categories, id: \.self) { category in
                    Text(category)
                        .font(.caption)
                        .foregroundColor(CandidColors.secondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(CandidColors.tertiaryBackground)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            SelectableTextView(text: viewModel.entry.body) { selectedText in
                viewModel.selectedText = selectedText
            }
            
            if let selected = viewModel.selectedText, !selected.isEmpty {
                Button(action: {
                    Task {
                        await viewModel.factCheck(selected)
                        if viewModel.lastFactCheckResult != nil {
                            showingFactCheckResult = true
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.shield")
                        Text("Fact Check Selection")
                    }
                    .font(.callout)
                    .foregroundColor(CandidColors.text)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(CandidColors.tertiaryBackground)
                    .cornerRadius(8)
                }
                .disabled(viewModel.isFactChecking)
            }
            
            if let error = viewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(CandidColors.secondaryBackground)
        .cornerRadius(12)
    }
    
    private var evidenceSection: some View {
        Group {
            if !viewModel.evidence.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Evidence")
                        .font(.headline)
                        .foregroundColor(CandidColors.text)
                    
                    ForEach(viewModel.evidence) { evidence in
                        EvidenceCard(evidence: evidence)
                    }
                }
            }
        }
    }
    
    private var factCheckResultsSection: some View {
        Group {
            if !viewModel.factCheckResults.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Fact Check Results")
                        .font(.headline)
                        .foregroundColor(CandidColors.text)
                    
                    ForEach(viewModel.factCheckResults) { result in
                        FactCheckResultCard(result: result)
                    }
                }
            }
        }
    }
}

// MARK: - Selectable Text View

struct SelectableTextView: UIViewRepresentable {
    let text: String
    let onSelection: (String) -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false // Disable scrolling to let it expand
        textView.font = .systemFont(ofSize: 17)
        textView.backgroundColor = .clear
        textView.textColor = UIColor(CandidColors.text)
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        
        // Ensure text wraps correctly
        textView.textContainer.widthTracksTextView = true
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        textView.delegate = context.coordinator
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelection: onSelection)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        let onSelection: (String) -> Void
        
        init(onSelection: @escaping (String) -> Void) {
            self.onSelection = onSelection
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            if let selectedRange = textView.selectedTextRange, !selectedRange.isEmpty {
                let selectedText = textView.text(in: selectedRange) ?? ""
                onSelection(selectedText)
            } else {
                onSelection("")
            }
        }
    }
}

// MARK: - Evidence Card

struct EvidenceCard: View {
    let evidence: Evidence
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(evidence.claimText)
                .font(.callout)
                .foregroundColor(CandidColors.text)
                .italic()
            
            if let title = evidence.sourceTitle, let url = evidence.sourceUrl {
                Link(destination: URL(string: url) ?? URL(string: "https://example.com")!) {
                    HStack {
                        Image(systemName: "link")
                            .font(.caption)
                        Text(title)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                    }
                    .foregroundColor(CandidColors.secondaryText)
                    .padding(10)
                    .background(CandidColors.tertiaryBackground)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(CandidColors.secondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Fact Check Result Card

struct FactCheckResultCard: View {
    let result: FactCheckResult
    
    private var scoreColor: Color {
        switch result.validityScore {
        case 0..<40: return .red
        case 40..<70: return .orange
        default: return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(result.claimText)
                    .font(.callout)
                    .foregroundColor(CandidColors.text)
                    .italic()
                
                Spacer()
                
                Text("\(result.validityScore)%")
                    .font(.headline)
                    .foregroundColor(scoreColor)
            }
            
            Text(result.reasoning)
                .font(.caption)
                .foregroundColor(CandidColors.secondaryText)
            
            if !result.evidence.isEmpty {
                Text("\(result.sourceCount) sources found")
                    .font(.caption2)
                    .foregroundColor(CandidColors.secondaryText)
            }
        }
        .padding(16)
        .background(CandidColors.secondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Fact Check Result View (Sheet)

struct FactCheckResultView: View {
    let result: FactCheckResult
    @Environment(\.dismiss) private var dismiss
    
    private var scoreColor: Color {
        switch result.validityScore {
        case 0..<40: return .red
        case 40..<70: return .orange
        default: return .green
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Score
                    HStack {
                        Text("Validity Score")
                            .font(.headline)
                            .foregroundColor(CandidColors.text)
                        Spacer()
                        Text("\(result.validityScore)%")
                            .font(.title.bold())
                            .foregroundColor(scoreColor)
                    }
                    .padding(16)
                    .background(CandidColors.secondaryBackground)
                    .cornerRadius(12)
                    
                    // Claim
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Claim")
                            .font(.headline)
                            .foregroundColor(CandidColors.text)
                        Text(result.claimText)
                            .font(.body)
                            .foregroundColor(CandidColors.text)
                            .italic()
                    }
                    .padding(16)
                    .background(CandidColors.secondaryBackground)
                    .cornerRadius(12)
                    
                    // Reasoning
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Analysis")
                            .font(.headline)
                            .foregroundColor(CandidColors.text)
                        Text(result.reasoning)
                            .font(.body)
                            .foregroundColor(CandidColors.text)
                    }
                    .padding(16)
                    .background(CandidColors.secondaryBackground)
                    .cornerRadius(12)
                    
                    // Sources
                    if !result.evidence.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sources (\(result.sourceCount))")
                                .font(.headline)
                                .foregroundColor(CandidColors.text)
                            
                            ForEach(result.evidence) { evidence in
                                if let title = evidence.sourceTitle, let url = evidence.sourceUrl {
                                    Link(destination: URL(string: url) ?? URL(string: "https://example.com")!) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(title)
                                                    .font(.callout)
                                                    .foregroundColor(CandidColors.text)
                                                Text(url)
                                                    .font(.caption)
                                                    .foregroundColor(CandidColors.secondaryText)
                                                    .lineLimit(1)
                                            }
                                            Spacer()
                                            Image(systemName: "arrow.up.right.square")
                                                .foregroundColor(CandidColors.secondaryText)
                                        }
                                        .padding(16)
                                        .background(CandidColors.secondaryBackground)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(CandidColors.background)
            .navigationTitle("Fact Check Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(CandidColors.text)
                }
            }
        }
    }
}
