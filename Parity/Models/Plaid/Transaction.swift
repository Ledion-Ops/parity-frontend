import Foundation

struct Transaction: Identifiable {
    let id: String
    let name: String
    let amount: Double
    let date: String

    init(plaidTransaction: PlaidTransaction) {
        self.id = plaidTransaction.transaction_id
        self.name = plaidTransaction.name
        self.amount = plaidTransaction.amount
        self.date = plaidTransaction.date
    }
}

struct PlaidTransaction: Decodable {
    let transaction_id: String
    let name: String
    let amount: Double
    let date: String
}
