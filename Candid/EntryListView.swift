import SwiftUI

struct EntryListView: View {
    @EnvironmentObject var viewModel: EntryListViewModel
    @State private var showingNewEntry = false
    @State private var selectedTemplate: EntryTemplate = .blank
    
    enum EntryTemplate {
        case blank, recipe, reflection, list
        
        var title: String {
            switch self {
            case .blank: return ""
            case .recipe: return "New Recipe"
            case .reflection: return "Daily Reflection"
            case .list: return "New List"
            }
        }
        
        var body: String {
            switch self {
            case .blank: return ""
            case .recipe: return "Ingredients:\n- \n\nInstructions:\n1. "
            case .reflection: return "What's on my mind today?\n\n\nWhat am I grateful for?\n\n"
            case .list: return "- \n- \n- "
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                CandidColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    VStack(spacing: 12) {
                        HStack {
                            Text("Candid")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(CandidColors.text)
                            Spacer()
                            
                            Menu {
                                Button("Blank Entry", action: { openTemplate(.blank) })
                                Button("Recipe", action: { openTemplate(.recipe) })
                                Button("Self-Reflection", action: { openTemplate(.reflection) })
                                Button("List", action: { openTemplate(.list) })
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(CandidColors.text)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        SearchBar(text: $viewModel.searchText)
                    }
                    .padding(.vertical, 10)
                    .background(CandidColors.background)
                    
                    if viewModel.isLoading && viewModel.entries.isEmpty {
                        ProgressView("Loading entries...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.entries.isEmpty {
                        emptyState
                    } else {
                        entryList
                    }
                }
            }
            // Hide default navigation bar to use our custom header
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingNewEntry) {
                NewEntryView(title: selectedTemplate.title, body: selectedTemplate.body) { _ in
                    Task {
                        await viewModel.loadEntries()
                    }
                }
            }
            .refreshable {
                await viewModel.loadEntries()
            }
        }
        .task {
            await viewModel.loadEntries()
        }
    }
    
    private func openTemplate(_ template: EntryTemplate) {
        selectedTemplate = template
        showingNewEntry = true
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(CandidColors.secondaryText)
            Text("No entries yet")
                .font(.title2)
                .foregroundColor(CandidColors.text)
            Text("Tap + to write your first entry")
                .font(.callout)
                .foregroundColor(CandidColors.secondaryText)
            
            if let error = viewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
        }
    }
    
    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredEntries) { entry in
                    NavigationLink(destination: EntryDetailView(entry: entry)) {
                        EntryRow(entry: entry)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(CandidColors.secondaryText)
            
            TextField("Search entries...", text: $text)
                .foregroundColor(CandidColors.text)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(CandidColors.secondaryText)
                }
            }
        }
        .padding(12)
        .background(CandidColors.secondaryBackground)
        .cornerRadius(10)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct EntryRow: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.title)
                    .font(.headline)
                    .foregroundColor(CandidColors.text)
                Spacer()
                
                // Display first category
                if let category = entry.primaryCategory {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(CandidColors.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CandidColors.tertiaryBackground)
                        .cornerRadius(8)
                }
            }
            
            Text(entry.body)
                .font(.callout)
                .foregroundColor(CandidColors.secondaryText)
                .lineLimit(2)
            
            Text(entry.date, style: .date)
                .font(.caption)
                .foregroundColor(CandidColors.secondaryText)
        }
        .padding(16)
        .background(CandidColors.secondaryBackground)
        .cornerRadius(12)
    }
}
