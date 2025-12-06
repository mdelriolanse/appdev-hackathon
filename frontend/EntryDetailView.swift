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
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.entry.title)
                .font(.system(size: CandidTypography.largeTitleSize, weight: CandidTypography.largeTitleWeight))
                .foregroundColor(CandidColors.text)
                .multilineTextAlignment(.leading)
            
            HStack(spacing: 12) {
                Text(viewModel.entry.date, style: .date)
                    .font(.system(size: CandidTypography.captionSize, weight: CandidTypography.captionWeight))
                    .foregroundColor(CandidColors.secondaryText)
                
                Spacer()
                
                // Display categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.entry.categories, id: \.self) { category in
                            Text(category.capitalized)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(CandidColors.text)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(CandidColors.background)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(CandidColors.borderLight, lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            SelectableTextView(text: viewModel.entry.body) { selectedText in
                viewModel.selectedText = selectedText
            }
            .frame(minHeight: 100) // Ensure readable height even if short
            
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
                        Image(systemName: "checkmark.shield.fill")
                        Text("Fact Check Selection")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(CandidColors.text)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(CandidColors.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: CandidShadows.card.color, radius: 4, x: 0, y: 2)
                }
                .disabled(viewModel.isFactChecking)
                .scaleEffect(viewModel.isFactChecking ? 0.98 : 1)
                .animation(.easeInOut, value: viewModel.isFactChecking)
            }
            
            if let error = viewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(20)
        .background(CandidColors.cardBackground)
        .cornerRadius(16)
        .shadow(color: CandidShadows.card.color, radius: 8, x: 0, y: 4)
    }
    
    private var evidenceSection: some View {
        Group {
            if !viewModel.evidence.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Evidence", systemImage: "link")
                        .font(.headline)
                        .foregroundColor(CandidColors.text)
                    
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.evidence.enumerated()), id: \.element.id) { index, evidence in
                            EvidenceCard(evidence: evidence)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1), value: viewModel.evidence.count)
                        }
                    }
                }
            }
        }
    }
    
    private var factCheckResultsSection: some View {
        Group {
            if !viewModel.factCheckResults.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Fact Checks", systemImage: "checkmark.seal")
                        .font(.headline)
                        .foregroundColor(CandidColors.text)
                    
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.factCheckResults.enumerated()), id: \.element.id) { index, result in
                            FactCheckResultCard(result: result)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1), value: viewModel.factCheckResults.count)
                        }
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
                .font(.system(size: 15, weight: .medium))
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
                    .foregroundColor(CandidColors.text)
                    .padding(10)
                    .background(CandidColors.background)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(CandidColors.borderLight, lineWidth: 1)
                    )
                }
            }
        }
        .padding(16)
        .background(CandidColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: CandidShadows.card.color, radius: 2, x: 0, y: 1)
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
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(CandidColors.text)
                    .italic()
                    .lineLimit(2)
                
                Spacer()
                
                Text("\(result.validityScore)%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(scoreColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(scoreColor.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Text(result.reasoning)
                .font(.system(size: 14))
                .foregroundColor(CandidColors.secondaryText)
            
            if !result.evidence.isEmpty {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("\(result.sourceCount) sources found")
                }
                .font(.caption)
                .foregroundColor(CandidColors.secondaryText)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(CandidColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: CandidShadows.card.color, radius: 2, x: 0, y: 1)
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
