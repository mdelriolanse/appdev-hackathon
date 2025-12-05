import SwiftUI
import UIKit

struct EntryDetailView: View {
    @StateObject private var viewModel: EntryDetailViewModel
    @State private var selectedRange: NSRange?
    
    init(entry: JournalEntry) {
        _viewModel = StateObject(wrappedValue: EntryDetailViewModel(entry: entry))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                content
                factChecks
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
        .sheet(isPresented: $viewModel.showingFactCheck) {
            if let text = viewModel.selectedText {
                FactCheckView(text: text, sources: viewModel.entry.factChecks.last?.sources ?? [])
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
                
                if let category = viewModel.entry.category {
                    Spacer()
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
            SelectableTextView(text: viewModel.entry.content) { selectedText in
                viewModel.selectedText = selectedText
            }
            
            if let selected = viewModel.selectedText, !selected.isEmpty {
                Button(action: {
                    Task {
                        await viewModel.factCheck(selected)
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.shield")
                        Text("Fact Check")
                    }
                    .font(.callout)
                    .foregroundColor(CandidColors.text)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(CandidColors.tertiaryBackground)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(CandidColors.secondaryBackground)
        .cornerRadius(12)
    }
    
    private var factChecks: some View {
        Group {
            if !viewModel.entry.factChecks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Fact Checks")
                        .font(.headline)
                        .foregroundColor(CandidColors.text)
                    
                    ForEach(viewModel.entry.factChecks) { factCheck in
                        FactCheckCard(factCheck: factCheck)
                    }
                }
            }
        }
    }
}

struct SelectableTextView: UIViewRepresentable {
    let text: String
    let onSelection: (String) -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .systemFont(ofSize: 17)
        textView.backgroundColor = .clear
        textView.textColor = UIColor(CandidColors.text)
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        
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
            if let selectedRange = textView.selectedTextRange,
               !selectedRange.isEmpty {
                let selectedText = textView.text(in: selectedRange) ?? ""
                onSelection(selectedText)
            } else {
                onSelection("")
            }
        }
    }
}

struct FactCheckCard: View {
    let factCheck: FactCheck
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(factCheck.text)
                .font(.callout)
                .foregroundColor(CandidColors.text)
                .italic()
            
            ForEach(factCheck.sources) { source in
                Link(destination: URL(string: source.url) ?? URL(string: "https://example.com")!) {
                    HStack {
                        Image(systemName: "link")
                            .font(.caption)
                        Text(source.title)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
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

struct FactCheckView: View {
    let text: String
    let sources: [Source]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Fact Check")
                        .font(.title2.bold())
                        .foregroundColor(CandidColors.text)
                    
                    Text(text)
                        .font(.body)
                        .foregroundColor(CandidColors.text)
                        .padding(16)
                        .background(CandidColors.secondaryBackground)
                        .cornerRadius(12)
                    
                    Text("Sources")
                        .font(.headline)
                        .foregroundColor(CandidColors.text)
                    
                    ForEach(sources) { source in
                        Link(destination: URL(string: source.url) ?? URL(string: "https://example.com")!) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(source.title)
                                        .font(.callout)
                                        .foregroundColor(CandidColors.text)
                                    Text(source.url)
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
                .padding(20)
            }
            .background(CandidColors.background)
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
