struct SyncResponse: Decodable {
    let accounts: [AccountResponse]
    let transactions: [PlaidTransaction]
}

struct AccountResponse: Identifiable, Decodable {
    let id: String // map this to _id from backend using CodingKeys
    let name: String
    let type: String?
    let subtype: String?
    let shared: Bool

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, type, subtype, shared
    }
}
