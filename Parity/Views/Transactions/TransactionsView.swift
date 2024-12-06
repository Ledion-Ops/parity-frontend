import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var userVM: UserViewModel
    @State private var searchText: String = ""

    var body: some View {
        NavigationView {
            VStack {
                if !transactionsByMonth.isEmpty {
                    List {
                        ForEach(transactionsByMonth, id: \.month) { sectionData in
                            Section(header: Text(sectionData.month)) {
                                ForEach(sectionData.transactions) { transaction in
                                    VStack(alignment: .leading) {
                                        Text(transaction.name)
                                            .font(.headline)
                                        Text(transaction.date)
                                            .font(.subheadline)
                                        Text("$\(transaction.amount, specifier: "%.2f")")
                                            .font(.body)
                                        Text("Classification: \(transaction.classification.capitalized)")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText)
                    .listStyle(.plain)
                } else {
                    Text(userVM.isLinked ? "No transactions available." : "Not linked. Please connect a bank account.")
                        .padding()
                }

                Button("Connect a Bank Account") {
                    userVM.createLinkToken()
                }
                .padding()
            }
            .navigationTitle("Transactions")
            .sheet(isPresented: $userVM.isLinkPresented) {
                if let linkToken = userVM.linkToken {
                    PlaidLinkView(isPresented: $userVM.isLinkPresented, linkToken: linkToken) { publicToken in
                        userVM.exchangePublicToken(publicToken)
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
        }
    }

    private var filteredTransactions: [Transaction] {
        if searchText.isEmpty {
            return userVM.transactions
        } else {
            return userVM.transactions.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }

    private var transactionsByMonth: [(month: String, transactions: [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction -> String in
            monthYearString(from: transaction.date)
        }

        return grouped.keys.sorted(by: { monthYearToDate($0) > monthYearToDate($1) }).map {
            (month: $0, transactions: grouped[$0]!)
        }
    }

    private func monthYearString(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return "" }

        let outFormatter = DateFormatter()
        outFormatter.dateFormat = "LLLL yyyy"
        return outFormatter.string(from: date)
    }

    private func monthYearToDate(_ monthYear: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.date(from: monthYear) ?? Date.distantPast
    }
}
