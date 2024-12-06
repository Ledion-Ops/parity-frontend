import SwiftUI

struct RootView: View {
    @EnvironmentObject var transactionsVM: TransactionsViewModel

    var body: some View {
        TabView {
            DashboardView()
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
        .task {
            if transactionsVM.allTransactions.isEmpty {
                transactionsVM.fetchTransactions()
            }
        }
    }
}
