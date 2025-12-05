import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = EntryListViewModel()
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EntryListView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Entries", systemImage: "book")
                }
                .tag(Tab.home)
            
            NavigationStack {
                CategoryBlocksView(categoryCounts: viewModel.categoryCounts)
            }
            .tabItem {
                Label("Categories", systemImage: "square.grid.2x2")
            }
            .tag(Tab.categories)
        }
    }
}
