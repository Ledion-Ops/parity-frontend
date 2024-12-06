import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var userVM: UserViewModel

    @State private var jointSpendingData: [LineChartDataPoint] = []
    @State private var mySpendingData: [LineChartDataPoint] = []
    @State private var currentMonthTransactions: [Transaction] = []
    @State private var comparisonValue: Double = 0.0

    var body: some View {
        NavigationView {
            ScrollView {
                if userVM.transactions.isEmpty {
                    // If no transactions, either not linked or no data
                    if userVM.isLinked {
                        Text("No transactions this month.")
                            .padding()
                    } else {
                        Text("Not linked. Please connect a bank account.")
                            .padding()
                    }
                } else {
                    VStack(spacing: 16) {
                        TabView {
                            LineChartView(
                                data: jointSpendingData,
                                title: "This Month's Joint Spending",
                                subtitle: "As of Today",
                                currentValue: jointSpendingData.last?.y ?? 0,
                                changeValue: comparisonValue,
                                changeDescription: "this month vs last month",
                                lineColor: .purple,
                                fillColor: .purple.opacity(0.3),
                                showAxes: false,
                                showEndDot: true
                            )
                            .padding()

                            LineChartView(
                                data: mySpendingData,
                                title: "My Spending This Month",
                                subtitle: "As of Today",
                                currentValue: mySpendingData.last?.y ?? 0,
                                changeValue: comparisonValue,
                                changeDescription: "this month vs last month",
                                lineColor: .blue,
                                fillColor: .blue.opacity(0.3),
                                showAxes: false,
                                showEndDot: true
                            )
                            .padding()
                        }
                        .tabViewStyle(.page(indexDisplayMode: .automatic))
                        .frame(height: 300)

                        Divider()
                            .padding([.top, .bottom], 8)

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
                    .onAppear {
                        prepareData()
                    }
                    .onChange(of: userVM.transactions) { _ in
                        prepareData()
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
    }

    private func prepareData() {
        let currentMonthData = currentMonthTransactionsData()
        currentMonthTransactions = currentMonthData.transactions
        jointSpendingData = cumulativeDataPoints(from: currentMonthData.transactions)
        mySpendingData = cumulativeDataPoints(from: currentMonthData.transactions)
        comparisonValue = calculateComparisonValue(currentMonthData: currentMonthData)
    }

    private func currentMonthTransactionsData() -> (transactions: [Transaction], startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: comps) else {
            return ([], now, now)
        }
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        let filtered = userVM.transactions.filter { txn in
            if let txnDate = dateFromString(txn.date) {
                return txnDate >= startOfMonth && txnDate <= endOfMonth
            }
            return false
        }

        return (filtered, startOfMonth, endOfMonth)
    }

    private func cumulativeDataPoints(from transactions: [Transaction]) -> [LineChartDataPoint] {
        let sortedTx = transactions.sorted {
            guard let d1 = dateFromString($0.date), let d2 = dateFromString($1.date) else { return false }
            return d1 < d2
        }
        var cumulative: Double = 0
        var points: [LineChartDataPoint] = []

        for txn in sortedTx {
            let valueToAdd = abs(txn.amount)
            cumulative += valueToAdd
            if let d = dateFromString(txn.date) {
                points.append(LineChartDataPoint(x: d, y: cumulative))
            }
        }

        return points
    }

    private func calculateComparisonValue(currentMonthData: (transactions: [Transaction], startDate: Date, endDate: Date)) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let dayOfMonth = calendar.component(.day, from: now)

        guard let lastMonthSameDay = calendar.date(byAdding: .month, value: -1, to: now) else {
            return 0
        }

        let lastMonthComps = calendar.dateComponents([.year, .month], from: lastMonthSameDay)
        guard let lastMonthStart = calendar.date(from: lastMonthComps) else { return 0 }

        let lastMonthDayOfMonthDate = calendar.date(bySetting: .day, value: dayOfMonth, of: lastMonthStart) ?? lastMonthStart

        let lastMonthTransactions = userVM.transactions.filter { txn in
            if let txnDate = dateFromString(txn.date) {
                return txnDate >= lastMonthStart && txnDate <= lastMonthDayOfMonthDate
            }
            return false
        }

        let lastMonthCumulative = cumulativeTotal(from: lastMonthTransactions)
        let currentMonthCumulative = cumulativeTotal(from: currentMonthData.transactions, upToDay: dayOfMonth, startDate: currentMonthData.startDate)

        return currentMonthCumulative - lastMonthCumulative
    }

    private func cumulativeTotal(from transactions: [Transaction], upToDay day: Int? = nil, startDate: Date? = nil) -> Double {
        var filtered = transactions
        if let d = day, let start = startDate {
            let calendar = Calendar.current
            let targetDate = calendar.date(bySetting: .day, value: d, of: start) ?? start
            filtered = transactions.filter {
                if let txnDate = dateFromString($0.date) {
                    return txnDate <= targetDate
                }
                return false
            }
        }

        return filtered.reduce(0.0) { $0 + abs($1.amount) }
    }

    private func dateFromString(_ str: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: str)
    }
}
