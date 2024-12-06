import SwiftUI

struct AccountsView: View {
    @EnvironmentObject var userVM: UserViewModel

    var body: some View {
        NavigationView {
            if userVM.accounts.isEmpty {
                Text("No accounts found. If you're not linked, link a bank account.")
                    .navigationTitle("Accounts")
            } else {
                List(userVM.accounts) { account in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.name)
                            .font(.headline)
                        HStack {
                            if let type = account.type {
                                Text("Type: \(type.capitalized)")
                                    .font(.subheadline)
                            }
                            if let subtype = account.subtype {
                                Text("Subtype: \(subtype.capitalized)")
                                    .font(.subheadline)
                            }
                        }
                        Text("Classification: \(account.shared ? "Joint" : "Private")")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .navigationTitle("Accounts")
            }
        }
    }
}
