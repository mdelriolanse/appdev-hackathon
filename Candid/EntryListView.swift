import SwiftUI

struct EntryListView: View {
    @EnvironmentObject var viewModel: EntryListViewModel
    @State private var showingNewEntry = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                CandidColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    SearchBar(text: $viewModel.searchText)
                    
                    if viewModel.entries.isEmpty {
                        emptyState
                    } else {
                        entryList
                    }
                }
            }
            .navigationTitle("Candid")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewEntry = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(CandidColors.text)
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                NewEntryView(onSave: {
                    viewModel.loadEntries()
                })
            }
        }
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
                if let category = entry.category {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(CandidColors.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CandidColors.tertiaryBackground)
                        .cornerRadius(8)
                }
            }
            
            Text(entry.content)
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
