import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var viewModel: TransactionsViewModel

    var body: some View {
        NavigationView {
            VStack {
                if !viewModel.transactionsByMonth.isEmpty {
                    List {
                        ForEach(viewModel.transactionsByMonth, id: \.month) { sectionData in
                            Section(header: Text(sectionData.month)) {
                                ForEach(sectionData.transactions) { transaction in
                                    VStack(alignment: .leading) {
                                        Text(transaction.name)
                                            .font(.headline)
                                        Text(transaction.date)
                                            .font(.subheadline)
                                        Text("$\(transaction.amount, specifier: "%.2f")")
                                            .font(.body)
                                            .foregroundColor(transaction.amount < 0 ? .red : .green)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .searchable(text: $viewModel.searchText)
                } else {
                    Text("No transactions available.")
                        .padding()
                }

                Button("Connect a Bank Account") {
                    viewModel.createLinkToken()
                }
                .padding()
            }
            .navigationTitle("Transactions")
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
