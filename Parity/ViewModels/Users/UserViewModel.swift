import Foundation
import Combine

class UserViewModel: ObservableObject {
    @Published var accounts: [AccountResponse] = []
    @Published var transactions: [Transaction] = []
    @Published var isLinked: Bool = false
    @Published var isLinkPresented: Bool = false
    @Published var linkToken: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        syncUserData()
    }

    func syncUserData() {
        guard let url = URL(string: "http://localhost:3000/user/sync") else { return }

        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { output -> Data in
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                guard httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: SyncResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                print(completion)
                if case .failure = completion {
                    print("Sync failed. Possibly user not linked.")
                }
            }, receiveValue: { [weak self] response in
                self?.accounts = response.accounts
                self?.transactions = response.transactions.map { Transaction(plaidTransaction: $0) }
                self?.isLinked = true
            })
            .store(in: &cancellables)
    }

    func afterLinkingAccount() {
        syncUserData()
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
                self?.afterLinkingAccount()
            })
            .store(in: &cancellables)
    }
}
