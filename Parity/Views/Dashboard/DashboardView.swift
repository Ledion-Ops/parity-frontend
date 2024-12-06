import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: TransactionsViewModel

    @State private var jointSpendingData: [LineChartDataPoint] = []
    @State private var mySpendingData: [LineChartDataPoint] = []
    @State private var currentMonthTransactions: [Transaction] = []
    @State private var comparisonValue: Double = 0.0 // For top right number on charts

    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.allTransactions.isEmpty {
                    ProgressView("Loading transactions...")
                        .padding()
                } else {
                    VStack(spacing: 16) {
                        // Charts
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
                                showAxes: false, // No axes for dashboard
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

                        // Current month transactions
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
                    .onChange(of: viewModel.allTransactions) { _ in
                        // If transactions update after load, refresh data
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

        let filtered = viewModel.allTransactions.filter { txn in
            if let txnDate = viewModel.dateFromString(txn.date) {
                return txnDate >= startOfMonth && txnDate <= endOfMonth
            }
            return false
        }

        return (filtered, startOfMonth, endOfMonth)
    }

    private func cumulativeDataPoints(from transactions: [Transaction]) -> [LineChartDataPoint] {
        let sortedTx = transactions.sorted {
            guard let d1 = viewModel.dateFromString($0.date), let d2 = viewModel.dateFromString($1.date) else { return false }
            return d1 < d2
        }
        var cumulative: Double = 0
        var points: [LineChartDataPoint] = []

        for txn in sortedTx {
            let valueToAdd = abs(txn.amount)
            cumulative += valueToAdd
            if let d = viewModel.dateFromString(txn.date) {
                points.append(LineChartDataPoint(x: d, y: cumulative))
            }
        }

        return points
    }

    private func calculateComparisonValue(currentMonthData: (transactions: [Transaction], startDate: Date, endDate: Date)) -> Double {
        let calendar = Calendar.current
        // If today is Dec 5, we check last month's (Nov) spending up to Nov 5.
        let now = Date()
        let dayOfMonth = calendar.component(.day, from: now)
        
        guard let lastMonthSameDay = calendar.date(byAdding: .month, value: -1, to: now) else {
            return 0
        }

        // Get last month's start and the dayOfMonth date
        let lastMonthComps = calendar.dateComponents([.year, .month], from: lastMonthSameDay)
        guard let lastMonthStart = calendar.date(from: lastMonthComps) else { return 0 }

        // dayOfMonth date for last month
        let lastMonthDayOfMonthDate = calendar.date(bySetting: .day, value: dayOfMonth, of: lastMonthStart) ?? lastMonthStart

        let lastMonthTransactions = viewModel.allTransactions.filter { txn in
            if let txnDate = viewModel.dateFromString(txn.date) {
                return txnDate >= lastMonthStart && txnDate <= lastMonthDayOfMonthDate
            }
            return false
        }

        let lastMonthCumulative = cumulativeTotal(from: lastMonthTransactions)
        let currentMonthCumulative = cumulativeTotal(from: currentMonthData.transactions, upToDay: dayOfMonth, startDate: currentMonthData.startDate)

        // difference = currentMonthCumulative - lastMonthCumulative
        return currentMonthCumulative - lastMonthCumulative
    }

    private func cumulativeTotal(from transactions: [Transaction], upToDay day: Int? = nil, startDate: Date? = nil) -> Double {
        var filtered = transactions
        if let d = day, let start = startDate {
            // If we want up to a certain day in current month
            let calendar = Calendar.current
            let targetDate = calendar.date(bySetting: .day, value: d, of: start) ?? start
            filtered = transactions.filter {
                if let txnDate = viewModel.dateFromString($0.date) {
                    return txnDate <= targetDate
                }
                return false
            }
        }

        return filtered.reduce(0.0) { $0 + abs($1.amount) }
    }
}
