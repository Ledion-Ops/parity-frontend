struct LinkTokenResponse: Decodable {
    let link_token: String
}

struct AccessTokenResponse: Decodable {
    let access_token: String
    let item_id: String
}

struct TransactionsResponse: Decodable {
    let transactions: [PlaidTransaction]
}
