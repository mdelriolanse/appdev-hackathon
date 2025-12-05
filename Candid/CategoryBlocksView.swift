import SwiftUI

struct CategoryBlocksView: View {
    let categoryCounts: [String: Int]
    
    var body: some View {
        ScrollView {
            if categoryCounts.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                    ForEach(Array(categoryCounts.sorted { $0.value > $1.value }), id: \.key) { category, count in
                        CategoryBlock(category: category, count: count, total: categoryCounts.values.reduce(0, +))
                    }
                }
                .padding(20)
            }
        }
        .background(CandidColors.background)
        .navigationTitle("Categories")
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
            Text(category)
                .font(.headline)
                .foregroundColor(CandidColors.text)
                .multilineTextAlignment(.center)
            Text("\(count)")
                .font(.caption)
                .foregroundColor(CandidColors.secondaryText)
        }
        .frame(width: size, height: size)
        .background(CandidColors.secondaryBackground)
        .cornerRadius(12)
    }
}
