import SwiftUI
import LinkKit

struct PlaidLinkView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var linkToken: String
    var onSuccess: (String) -> Void

    class Coordinator {
        var handler: Handler?
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let hostingController = UIViewController()

        var linkConfiguration = LinkTokenConfiguration(token: linkToken) { linkSuccess in
            onSuccess(linkSuccess.publicToken)
            isPresented = false
        }

        linkConfiguration.onExit = { linkExit in
            if let error = linkExit.error {
                print("Plaid Link exited with error: \(error.localizedDescription)")
            } else {
                print("Plaid Link exited by user.")
            }
            isPresented = false
        }

        let result = Plaid.create(linkConfiguration)
        switch result {
        case .failure(let error):
            print("Failed to create Plaid Handler: \(error.localizedDescription)")
        case .success(let handler):
            context.coordinator.handler = handler
            DispatchQueue.main.async {
                handler.open(presentUsing: .viewController(hostingController))
            }
        }

        return hostingController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
