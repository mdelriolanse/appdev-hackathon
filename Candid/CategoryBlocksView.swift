import SwiftUI

struct CategoryBlocksView: View {
    @EnvironmentObject var viewModel: EntryListViewModel
    let categoryCounts: [String: Int]
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Text("Categories")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(CandidColors.text)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(CandidColors.background)
            
            ScrollView {
                if categoryCounts.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                        ForEach(Array(categoryCounts.sorted { $0.value > $1.value }.enumerated()), id: \.element.key) { index, element in
                            let (category, count) = element
                            NavigationLink(destination: CategoryEntryListView(category: category, allEntries: viewModel.entries)) {
                                CategoryBlock(category: category, count: count, total: categoryCounts.values.reduce(0, +))
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: categoryCounts)
                }
            }
        }
        .background(CandidColors.background)
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 48))
                .foregroundColor(CandidColors.secondaryText)
            Text("No categories yet")
                .font(.title2)
                .foregroundColor(CandidColors.text)
            Text("Write entries to see categories")
                .font(.callout)
                .foregroundColor(CandidColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

struct CategoryEntryListView: View {
    let category: String
    let allEntries: [JournalEntry]
    
    var filteredEntries: [JournalEntry] {
        allEntries.filter { $0.categories.contains(category) }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredEntries) { entry in
                    NavigationLink(destination: EntryDetailView(entry: entry)) {
                        EntryRow(entry: entry)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(20)
        }
        .background(CandidColors.background)
        .navigationTitle(category.capitalized)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct CategoryBlock: View {
    let category: String
    let count: Int
    let total: Int
    
    private var size: CGFloat {
        let ratio = CGFloat(count) / CGFloat(total)
        return max(120, 200 * sqrt(ratio))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(category.capitalized)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(CandidColors.text)
                .multilineTextAlignment(.center)
            
            Text("\(count) entries")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(CandidColors.secondaryText)
        }
        .frame(width: size, height: size)
        .background(CandidColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: CandidShadows.card.color, radius: CandidShadows.card.radius, x: CandidShadows.card.x, y: CandidShadows.card.y)
    }
}
