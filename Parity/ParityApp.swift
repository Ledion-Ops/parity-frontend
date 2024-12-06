import SwiftUI

@main
struct MyApp: App {
    @StateObject var transactionsVM = TransactionsViewModel()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(transactionsVM)
        }
    }
}
