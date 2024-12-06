struct PlaidTransaction: Decodable {
    let plaidTransactionId: String
    let name: String
    let amount: Double
    let date: String
    let classification: String? // Add this new field that the backend returns
}

struct Transaction: Identifiable, Equatable {
    let id: String
    let name: String
    let amount: Double
    let date: String
    let classification: String

    init(plaidTransaction: PlaidTransaction) {
        self.id = plaidTransaction.plaidTransactionId
        self.name = plaidTransaction.name
        self.amount = plaidTransaction.amount
        self.date = plaidTransaction.date
        self.classification = plaidTransaction.classification ?? "mine"
    }
}
