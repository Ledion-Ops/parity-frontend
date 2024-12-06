import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if !viewModel.transactions.isEmpty {
                    List(viewModel.transactions) { transaction in
                        VStack(alignment: .leading) {
                            Text(transaction.name)
                                .font(.headline)
                            Text(transaction.date)
                                .font(.subheadline)
                            Text("$\(transaction.amount, specifier: "%.2f")")
                                .font(.body)
                        }
                    }
                }

                Button("Connect a Bank Account") {
                    viewModel.createLinkToken()
                }
                .padding()
            }
            .navigationBarTitle("Transactions")
            .sheet(isPresented: $viewModel.isLinkPresented) {
                if let linkToken = viewModel.linkToken {
                    PlaidLinkView(isPresented: $viewModel.isLinkPresented, linkToken: linkToken) { publicToken in
                        viewModel.exchangePublicToken(publicToken)
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
        }
    }
}
