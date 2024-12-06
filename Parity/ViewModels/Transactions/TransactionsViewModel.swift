import Foundation
import Combine

class TransactionsViewModel: ObservableObject {
    @Published var isLinkPresented = false
    @Published var linkToken: String?
    @Published var allTransactions: [Transaction] = []
    @Published var searchText: String = ""

    private var cancellables = Set<AnyCancellable>()

    init() {
        fetchTransactionsOnStartup()
    }

    private func fetchTransactionsOnStartup() {
        guard let url = URL(string: "http://localhost:3000/plaid/transactions") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!

        let parameters: [String: Any] = [
            "start_date": formatter.string(from: startDate),
            "end_date": formatter.string(from: endDate)
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output -> Data in
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                if httpResponse.statusCode == 400 {
                    return Data()
                }
                if httpResponse.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: TransactionsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error fetching transactions on startup: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                self?.allTransactions = response.transactions.map { Transaction(plaidTransaction: $0) }
            })
            .store(in: &cancellables)
    }

    func createLinkToken() {
        guard let url = URL(string: "http://localhost:3000/plaid/create_link_token") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: LinkTokenResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error creating link token: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                self?.linkToken = response.link_token
                self?.isLinkPresented = true
            })
            .store(in: &cancellables)
    }

    func exchangePublicToken(_ publicToken: String) {
        guard let url = URL(string: "http://localhost:3000/plaid/get_access_token") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let parameters = ["public_token": publicToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: AccessTokenResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error exchanging public token: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                self?.fetchTransactions()
            })
            .store(in: &cancellables)
    }

    func fetchTransactions() {
        guard let url = URL(string: "http://localhost:3000/plaid/transactions") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!

        let parameters: [String: Any] = [
            "start_date": formatter.string(from: startDate),
            "end_date": formatter.string(from: endDate)
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: TransactionsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error fetching transactions: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                self?.allTransactions = response.transactions.map { Transaction(plaidTransaction: $0) }
            })
            .store(in: &cancellables)
    }

    // Searching & Grouping
    var filteredTransactions: [Transaction] {
        if searchText.isEmpty {
            return allTransactions
        } else {
            return allTransactions.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }

    var transactionsByMonth: [(month: String, transactions: [Transaction])] {
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
