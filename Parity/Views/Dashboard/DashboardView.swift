import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: TransactionsViewModel

    // We assume all transactions are from the last 30 days as per the VM’s logic.
    // Let's extract a current month cumulative spending dataset.
    @State private var jointSpendingData: [LineChartDataPoint] = []
    @State private var mySpendingData: [LineChartDataPoint] = []
    @State private var currentMonthTransactions: [Transaction] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    TabView {
                        LineChartView(
                            data: jointSpendingData,
                            title: "Joint Spending",
                            subtitle: "As of Today",
                            currentValue: jointSpendingData.last?.y ?? 0,
                            changeValue: 1019, // Integrate real logic here if needed
                            changeDescription: "in the last month",
                            lineColor: .purple,
                            fillColor: .purple.opacity(0.3),
                            xAxisDates: xAxisDates(for: jointSpendingData)
                        )
                        .padding()

                        // "My Spending This Month" chart
                        LineChartView(
                            data: mySpendingData,
                            title: "My Spending",
                            subtitle: "As of Today",
                            currentValue: mySpendingData.last?.y ?? 0,
                            changeValue: 200, // Integrate real logic here if needed
                            changeDescription: "this month",
                            lineColor: .blue,
                            fillColor: .blue.opacity(0.3),
                            xAxisDates: xAxisDates(for: mySpendingData)
                        )
                        .padding()
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(height: 300) // Chart height + padding
                }
                .onAppear {
                    prepareData()
                }

                Divider()
                    .padding([.top, .bottom], 8)

                // Show current month’s transactions below the charts
                if !currentMonthTransactions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This Month's Transactions")
                            .font(.headline)
                            .padding(.leading)

                        ForEach(currentMonthTransactions) { transaction in
                            VStack(alignment: .leading) {
                                Text(transaction.name)
                                    .font(.headline)
                                Text(transaction.date)
                                    .font(.subheadline)
                                Text("$\(transaction.amount, specifier: "%.2f")")
                                    .font(.body)
                                    .foregroundColor(transaction.amount < 0 ? .red : .green)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
                            .padding([.leading, .trailing])
                        }
                    }
                    .padding(.bottom, 20)
                } else {
                    Text("No transactions this month.")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .navigationTitle("Dashboard")
        }
    }

    private func prepareData() {
        let currentMonthData = currentMonthTransactionsData()
        currentMonthTransactions = currentMonthData.transactions

        // Create cumulative sums for jointSpendingData and mySpendingData
        // For demonstration, assume all transactions are joint spending.
        // For "My Spending", we could filter by a condition (e.g., transaction.name.contains("My Account"))
        jointSpendingData = cumulativeDataPoints(from: currentMonthData.transactions)
        mySpendingData = cumulativeDataPoints(from: currentMonthData.transactions)
    }

    private func currentMonthTransactionsData() -> (transactions: [Transaction], startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let now = Date()
        // Start of this month
        let comps = calendar.dateComponents([.year, .month], from: now)
        let startOfMonth = calendar.date(from: comps)!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        let filtered = viewModel.allTransactions.filter { txn in
            if let txnDate = dateFromString(txn.date) {
                return txnDate >= startOfMonth && txnDate <= endOfMonth
            }
            return false
        }

        return (filtered, startOfMonth, endOfMonth)
    }

    private func cumulativeDataPoints(from transactions: [Transaction]) -> [LineChartDataPoint] {
        // Sort transactions by date
        let sortedTx = transactions.sorted { dateFromString($0.date)! < dateFromString($1.date)! }
        var cumulative: Double = 0
        var points: [LineChartDataPoint] = []

        for txn in sortedTx {
            // Assume negative amounts represent spending; add absolute value to the cumulative sum
            let valueToAdd = abs(txn.amount)
            cumulative += valueToAdd
            if let d = dateFromString(txn.date) {
                points.append(LineChartDataPoint(x: d, y: cumulative))
            }
        }

        return points
    }

    private func xAxisDates(for data: [LineChartDataPoint]) -> [Date] {
        guard let first = data.first?.x, let last = data.last?.x else { return [] }
        let calendar = Calendar.current
        // Show 3 ticks: start of month, midpoint, end of month
        let midDate = calendar.date(byAdding: .day, value: 15, to: first)
        return [first, midDate ?? first, last].sorted()
    }

    private func dateFromString(_ str: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: str)
    }
}
