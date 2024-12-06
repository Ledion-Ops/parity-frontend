import SwiftUI
import Charts

struct LineChartDataPoint: Identifiable {
    let id = UUID()
    let x: Date
    let y: Double
}

struct LineChartView: View {
    var data: [LineChartDataPoint]
    var title: String
    var subtitle: String
    var currentValue: Double
    var changeValue: Double
    var changeDescription: String
    var lineColor: Color = .purple
    var fillColor: Color = .purple.opacity(0.3)
    var showAxes: Bool = true
    var showEndDot: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and Value
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(currentValue))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .lineLimit(1)
                }

                Spacer()

                // Change description (no line break)
                let isPositive = changeValue >= 0
                HStack {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(isPositive ? .green : .red)
                    Text("\(formatCurrency(changeValue)) \(changeDescription)")
                        .foregroundColor(isPositive ? .green : .red)
                        .font(.callout)
                        .lineLimit(1)
                }
            }

            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Date", point.x),
                        y: .value("Amount", point.y)
                    )
                    .foregroundStyle(lineColor)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.x),
                        y: .value("Amount", point.y)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [fillColor, .clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                if showEndDot, let lastPoint = data.last {
                    PointMark(
                        x: .value("Date", lastPoint.x),
                        y: .value("Amount", lastPoint.y)
                    )
                    .symbol(.circle)
                    .foregroundStyle(lineColor)
                }
            }
            .frame(height: 150)
            .padding(.top, 8)
            .chartXAxis(showAxes ? .automatic : .hidden)
            .chartYAxis(showAxes ? .automatic : .hidden)

            Text(subtitle)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
