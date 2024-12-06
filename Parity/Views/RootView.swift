import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            DashboardView() // Uses transactions from environment
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }

            SpendingView()
                .tabItem {
                    Label("Spending", systemImage: "chart.bar.fill")
                }

            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
        }
    }
}
