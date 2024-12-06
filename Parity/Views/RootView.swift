import SwiftUI

struct RootView: View {
    @EnvironmentObject var userVM: UserViewModel

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }

            AccountsView()
                .tabItem {
                    Label("Accounts", systemImage: "banknote")
                }

            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
        }
    }
}
