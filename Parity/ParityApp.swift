import SwiftUI

@main
struct MyAppApp: App {
    @StateObject var userVM = UserViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(userVM)
        }
    }
}
