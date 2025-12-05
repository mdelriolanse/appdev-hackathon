import SwiftUI

struct EntryListView: View {
    @EnvironmentObject var viewModel: EntryListViewModel
    @State private var showingNewEntry = false
    @State private var selectedTemplate: EntryTemplate = .blank
    
    enum EntryTemplate {
        case blank, recipe, reflection
        
        var title: String {
            switch self {
            case .blank: return ""
            case .recipe: return "New Recipe"
            case .reflection: return "Daily Reflection"
            }
        }
        
        var body: String {
            switch self {
            case .blank: return ""
            case .recipe: return "Ingredients:\n- \n\nInstructions:\n1. "
            case .reflection: return "What's on my mind today?\n\n\nWhat am I grateful for?\n\n"
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
                .font(.system(size: 60))
                .foregroundColor(CandidColors.secondaryText.opacity(0.5))
                .symbolEffect(.bounce, value: showingNewEntry)
            
            Text("No entries yet")
                .font(.system(size: 20, weight: CandidTypography.bodyWeight))
                .foregroundColor(CandidColors.text)
            
            Text("Tap + to write your first entry")
                .font(.system(size: CandidTypography.bodySize, weight: CandidTypography.bodyWeight))
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
                            .cardStyle()
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
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
                .font(.system(size: CandidTypography.bodySize))
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(CandidColors.secondaryText)
                }
            }
        }
        .padding(12)
        .background(CandidColors.cardBackground)
        .cornerRadius(10)
        .shadow(color: CandidShadows.card.color, radius: 2, x: 0, y: 1)
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
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(CandidColors.text)
                Spacer()
                
                // Display first category
                if let category = entry.primaryCategory {
                    Text(category.capitalized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(CandidColors.text)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CandidColors.background)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(CandidColors.borderLight, lineWidth: 0.5)
                        )
                }
            }
            
            Text(entry.body)
                .font(.system(size: CandidTypography.bodySize))
                .foregroundColor(CandidColors.secondaryText)
                .lineLimit(2)
                .padding(.top, 2)
            
            Text(entry.date, style: .date)
                .font(.system(size: 12))
                .foregroundColor(CandidColors.secondaryText.opacity(0.8))
                .padding(.top, 4)
        }
        .padding(16)
    }
}
