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
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12, alignment: .top)], spacing: 12) {
                        ForEach(Array(categoryCounts.sorted { $0.value > $1.value }.enumerated()), id: \.element.key) { index, element in
                            let (category, count) = element
                            NavigationLink(destination: CategoryEntryListView(category: category, allEntries: viewModel.entries)) {
                                CategoryBlock(category: category, count: count)
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
    @Environment(\.dismiss) private var dismiss
    let category: String
    let allEntries: [JournalEntry]
    
    var filteredEntries: [JournalEntry] {
        allEntries.filter { $0.categories.contains(category) }
    }
    
    var body: some View {
        ZStack {
            CandidColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header with Back Button
                HStack(spacing: 16) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(CandidColors.text)
                    }
                    
                    Text(category.capitalized)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(CandidColors.text)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(CandidColors.background)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredEntries) { entry in
                            NavigationLink(destination: EntryDetailView(entry: entry)) {
                                EntryRow(entry: entry)
                                    .cardStyle()
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct CategoryBlock: View {
    let category: String
    let count: Int
    
    private var height: CGFloat {
        // Base height for an empty or single entry category
        let baseHeight: CGFloat = 120
        // How much to grow per entry
        let growthPerEntry: CGFloat = 10
        // Maximum height to prevent it from getting too large
        let maxHeight: CGFloat = 220
        
        // Calculate height based on absolute count to ensure it grows when entries are added
        let calculatedHeight = baseHeight + (CGFloat(max(0, count - 1)) * growthPerEntry)
        return min(maxHeight, calculatedHeight)
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
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(CandidColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: CandidShadows.card.color, radius: CandidShadows.card.radius, x: CandidShadows.card.x, y: CandidShadows.card.y)
    }
}
