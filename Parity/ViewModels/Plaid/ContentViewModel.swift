import Foundation
import Combine

class ContentViewModel: ObservableObject {
    @Published var isLinkPresented = false
    @Published var linkToken: String?
    @Published var transactions: [Transaction] = []

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
                switch completion {
                case .failure(let error):
                    print("Error fetching transactions on startup: \(error.localizedDescription)")
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] response in
                self?.transactions = response.transactions.map { Transaction(plaidTransaction: $0) }
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
                // No need to store access_token locally. The backend has it.
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
                self?.transactions = response.transactions.map { Transaction(plaidTransaction: $0) }
            })
            .store(in: &cancellables)
    }
}
