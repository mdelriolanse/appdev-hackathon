import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = EntryListViewModel()
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            EntryListView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Entries", systemImage: "book")
                }
                .tag(Tab.entries)
            
            NavigationStack {
                CategoryBlocksView(categoryCounts: viewModel.categoryCounts)
            }
            .tabItem {
                Label("Categories", systemImage: "square.grid.2x2")
            }
            .tag(Tab.categories)
            .onAppear {
                viewModel.loadEntries()
            }
        }
        .onAppear {
            viewModel.loadEntries()
        }
    }
}
