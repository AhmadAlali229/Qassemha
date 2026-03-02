//
//  HistoryView.swift
//  Qassemha
//
//  Created by Harjot Singh on 21/09/25.
//

import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @ObservedObject private var walletManager = WalletManager.shared

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StoredReceipt.date, ascending: false)],
        animation: .default)
    private var receipts: FetchedResults<StoredReceipt>

    @State private var selectedFilter = "All"
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var showingReports = false
    @State private var showingExportOptions = false
    @State private var selectedTransaction: UnifiedTransaction?
    @State private var dateRange: DateRangeOption = .all
    @State private var allTransactions: [UnifiedTransaction] = []
    @State private var isLoadingTransactions = false

    private let filterOptions = ["All", "Completed", "Pending", "This Week", "This Month"]

    enum DateRangeOption: String, CaseIterable {
        case all = "All Time"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case custom = "Custom"
    }

    // Load transactions once and cache them
    private func loadAllTransactions() {
        guard !isLoadingTransactions else { return }
        isLoadingTransactions = true

        // Perform heavy work asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            var transactions: [UnifiedTransaction] = []

            // Add receipts
            DispatchQueue.main.sync {
                for receipt in receipts {
                    transactions.append(UnifiedTransaction(
                        id: receipt.receiptID ?? UUID(),
                        title: receipt.storeName ?? "Unknown Store",
                        date: receipt.date ?? Date(),
                        total: receipt.total,
                        currency: receipt.currency ?? "SAR",
                        status: receipt.receiptType == "sent" ? "completed" : "pending",
                        type: .receipt,
                        paymentMethod: nil,
                        category: receipt.category ?? "general",
                        items: (receipt.items?.allObjects as? [StoredReceiptItem])?.map { $0.name ?? "" } ?? [],
                        relatedEntity: receipt
                    ))
                }
            }

            // Add wallet transactions
            let walletTransactions = walletManager.getAllTransactions()
            for transaction in walletTransactions {
                transactions.append(UnifiedTransaction(
                    id: transaction.id,
                    title: transaction.description.isEmpty ? transaction.typeDisplay : transaction.description,
                    date: transaction.createdAt,
                    total: transaction.amount,
                    currency: transaction.currency,
                    status: transaction.status,
                    type: .walletTransaction,
                    paymentMethod: transaction.paymentMethod,
                    category: transaction.type,
                    items: [],
                    relatedEntity: transaction
                ))
            }

            // Sort transactions
            let sortedTransactions = transactions.sorted { $0.date > $1.date }

            // Update UI on main thread
            DispatchQueue.main.async {
                self.allTransactions = sortedTransactions
                self.isLoadingTransactions = false
            }
        }
    }

    var filteredTransactions: [UnifiedTransaction] {
        var filtered = allTransactions

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { transaction in
                transaction.title.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply status/time filter
        switch selectedFilter {
        case "Completed":
            filtered = filtered.filter { $0.status == "completed" }
        case "Pending":
            filtered = filtered.filter { $0.status == "pending" }
        case "This Week":
            let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            filtered = filtered.filter { $0.date >= oneWeekAgo }
        case "This Month":
            let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            filtered = filtered.filter { $0.date >= oneMonthAgo }
        default:
            break
        }

        // Apply date range filter
        filtered = filtered.filter { transaction in
            switch dateRange {
            case .all:
                return true
            case .thisWeek:
                let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
                return transaction.date >= oneWeekAgo
            case .thisMonth:
                let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                return transaction.date >= oneMonthAgo
            case .lastMonth:
                let startOfThisMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
                let startOfLastMonth = Calendar.current.date(byAdding: .month, value: -1, to: startOfThisMonth) ?? Date()
                return transaction.date >= startOfLastMonth && transaction.date < startOfThisMonth
            case .custom:
                return true
            }
        }

        return filtered
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Analytics Summary Card
                if !allTransactions.isEmpty {
                    AnalyticsSummaryCard(transactions: filteredTransactions)
                        .padding()
                        .transition(.opacity)
                }

                // Quick Actions
                HStack(spacing: 12) {
                    Button(action: { showingReports = true }) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text("Reports")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                         startPoint: .leading,
                                         endPoint: .trailing)
                        )
                        .cornerRadius(10)
                    }

                    Button(action: { showingExportOptions = true }) {
                        HStack {
                            Image(systemName: "arrow.down.doc.fill")
                            Text("Export")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                         startPoint: .leading,
                                         endPoint: .trailing)
                        )
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Search and Filters
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Enhanced Search Field
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(searchText.isEmpty ? .secondary : .blue)

                            TextField("Search by name, category...", text: $searchText)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                                .font(.system(size: 15, weight: .regular))

                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(searchText.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1.5)
                        )

                        // Filter Button
                        Button(action: { showingFilters = true }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedFilter != "All" || dateRange != .all ? Color.blue : Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                                    .frame(width: 48, height: 48)

                                Image(systemName: selectedFilter != "All" || dateRange != .all ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(selectedFilter != "All" || dateRange != .all ? .white : .blue)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: searchText)

                    // Active filter indicator
                    if selectedFilter != "All" || dateRange != .all {
                        HStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "line.3.horizontal.decrease")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.blue)

                                Text(selectedFilter)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.blue)

                                if dateRange != .all {
                                    Text("•")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.blue.opacity(0.5))

                                    Text(dateRange.rawValue)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.1))
                            )

                            Spacer()

                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedFilter = "All"
                                    dateRange = .all
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Clear")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.red.opacity(0.1))
                                )
                            }
                        }
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedFilter)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dateRange)

                // Transaction List
                if isLoadingTransactions && allTransactions.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()

                        Text("Loading transactions...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredTransactions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No Transactions")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(searchText.isEmpty ? "Your transaction history will appear here" : "No transactions match your search")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(groupedTransactionsByDate(), id: \.key) { group in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(group.key)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                        .padding(.top, 8)

                                    ForEach(group.value) { transaction in
                                        UnifiedTransactionCard(transaction: transaction)
                                            .padding(.horizontal)
                                            .onTapGesture {
                                                selectedTransaction = transaction
                                            }
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Transaction History")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if allTransactions.isEmpty {
                    loadAllTransactions()
                }
            }
            .onChange(of: receipts.count) {
                loadAllTransactions()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        loadAllTransactions()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                TransactionFiltersView(
                    selectedFilter: $selectedFilter,
                    dateRange: $dateRange,
                    isPresented: $showingFilters
                )
            }
            .sheet(isPresented: $showingReports) {
                TransactionReportsView(transactions: filteredTransactions)
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView(transactions: filteredTransactions)
            }
            .sheet(item: $selectedTransaction) { transaction in
                HistoryTransactionDetailView(transaction: transaction)
            }
        }
    }

    // Group transactions by date
    private func groupedTransactionsByDate() -> [(key: String, value: [UnifiedTransaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction -> String in
            let formatter = DateFormatter()
            let now = Date()
            let calendar = Calendar.current

            if calendar.isDate(transaction.date, inSameDayAs: now) {
                return "Today"
            } else if calendar.isDate(transaction.date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now) {
                return "Yesterday"
            } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(transaction.date) == true {
                formatter.dateFormat = "EEEE"
                return formatter.string(from: transaction.date)
            } else {
                formatter.dateStyle = .medium
                return formatter.string(from: transaction.date)
            }
        }

        return grouped.sorted { (first, second) -> Bool in
            if first.key == "Today" { return true }
            if second.key == "Today" { return false }
            if first.key == "Yesterday" { return true }
            if second.key == "Yesterday" { return false }

            guard let firstDate = first.value.first?.date,
                  let secondDate = second.value.first?.date else {
                return false
            }
            return firstDate > secondDate
        }
    }
}

// MARK: - Unified Transaction Model

enum TransactionType {
    case receipt
    case walletTransaction
}

struct UnifiedTransaction: Identifiable {
    let id: UUID
    let title: String
    let date: Date
    let total: Double
    let currency: String
    let status: String
    let type: TransactionType
    let paymentMethod: String?
    let category: String
    let items: [String]
    let relatedEntity: Any

    var statusColor: Color {
        switch status.lowercased() {
        case "completed": return .green
        case "pending": return .orange
        case "failed": return .red
        default: return .gray
        }
    }

    var typeIcon: String {
        switch type {
        case .receipt: return "receipt"
        case .walletTransaction: return "dollarsign.circle"
        }
    }
}

// MARK: - Analytics Summary Card

struct AnalyticsSummaryCard: View {
    let transactions: [UnifiedTransaction]
    @ObservedObject private var currencyManager = CurrencyManager.shared

    private var totalSpent: Double {
        transactions.filter { $0.type == .receipt || $0.category == "payment" }.reduce(0) { $0 + $1.total }
    }

    private var totalReceived: Double {
        transactions.filter { $0.category == "received" || $0.category == "refund" }.reduce(0) { $0 + $1.total }
    }

    private var pendingCount: Int {
        transactions.filter { $0.status == "pending" }.count
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Spent")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(currencyManager.format(amount: totalSpent))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Received")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(currencyManager.format(amount: totalReceived))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transactions")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("\(transactions.count)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Pending")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("\(pendingCount)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Unified Transaction Card

struct UnifiedTransactionCard: View {
    let transaction: UnifiedTransaction
    @ObservedObject private var currencyManager = CurrencyManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(transaction.statusColor.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: transaction.typeIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(transaction.statusColor)
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(transaction.category.capitalized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    if let paymentMethod = transaction.paymentMethod, !paymentMethod.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(paymentMethod)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Amount and Status
            VStack(alignment: .trailing, spacing: 4) {
                Text(currencyManager.format(amount: transaction.total))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(transaction.statusColor)
                        .frame(width: 6, height: 6)

                    Text(transaction.status.capitalized)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(transaction.statusColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Transaction Filters View

struct TransactionFiltersView: View {
    @Binding var selectedFilter: String
    @Binding var dateRange: HistoryView.DateRangeOption
    @Binding var isPresented: Bool

    private let statusFilters = [
        ("All", "All transactions"),
        ("Completed", "Fully settled transactions"),
        ("Pending", "Outstanding payments"),
        ("This Week", "Last 7 days"),
        ("This Month", "Last 30 days")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Status Filters
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Status")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)

                        ForEach(statusFilters, id: \.0) { filter in
                            Button(action: {
                                selectedFilter = filter.0
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(filter.0)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)

                                        Text(filter.1)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if selectedFilter == filter.0 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedFilter == filter.0 ? Color.blue : Color.gray.opacity(0.2), lineWidth: selectedFilter == filter.0 ? 2 : 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedFilter == filter.0 ? Color.blue.opacity(0.05) : Color.clear)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    Divider()

                    // Date Range Filters
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Date Range")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)

                        ForEach(HistoryView.DateRangeOption.allCases, id: \.self) { range in
                            Button(action: {
                                dateRange = range
                            }) {
                                HStack {
                                    Text(range.rawValue)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)

                                    Spacer()

                                    if dateRange == range {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(dateRange == range ? Color.green : Color.gray.opacity(0.2), lineWidth: dateRange == range ? 2 : 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(dateRange == range ? Color.green.opacity(0.05) : Color.clear)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedFilter = "All"
                        dateRange = .all
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Transaction Reports View

struct TransactionReportsView: View {
    let transactions: [UnifiedTransaction]
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPeriod: ReportPeriod = .thisMonth
    @State private var showingCategoryBreakdown = false

    enum ReportPeriod: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case last3Months = "Last 3 Months"
        case last6Months = "Last 6 Months"
        case thisYear = "This Year"
    }

    private func filteredTransactionsByPeriod() -> [UnifiedTransaction] {
        let calendar = Calendar.current
        let now = Date()

        return transactions.filter { transaction in
            switch selectedPeriod {
            case .thisWeek:
                let oneWeekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
                return transaction.date >= oneWeekAgo
            case .thisMonth:
                let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
                return transaction.date >= oneMonthAgo
            case .lastMonth:
                let startOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
                let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfThisMonth) ?? now
                return transaction.date >= startOfLastMonth && transaction.date < startOfThisMonth
            case .last3Months:
                let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
                return transaction.date >= threeMonthsAgo
            case .last6Months:
                let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now) ?? now
                return transaction.date >= sixMonthsAgo
            case .thisYear:
                let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
                return transaction.date >= startOfYear
            }
        }
    }

    private var periodTransactions: [UnifiedTransaction] {
        filteredTransactionsByPeriod()
    }

    private var totalSpent: Double {
        periodTransactions.filter { $0.type == .receipt || $0.category == "payment" }.reduce(0) { $0 + $1.total }
    }

    private var totalReceived: Double {
        periodTransactions.filter { $0.category == "received" || $0.category == "refund" }.reduce(0) { $0 + $1.total }
    }

    private var netAmount: Double {
        totalReceived - totalSpent
    }

    private var categoryBreakdown: [(category: String, total: Double, count: Int)] {
        let grouped = Dictionary(grouping: periodTransactions, by: { $0.category })
        return grouped.map { (category: $0.key, total: $0.value.reduce(0) { $0 + $1.total }, count: $0.value.count) }
            .sorted { $0.total > $1.total }
    }

    private var averageTransactionValue: Double {
        guard !periodTransactions.isEmpty else { return 0 }
        return periodTransactions.reduce(0) { $0 + $1.total } / Double(periodTransactions.count)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ReportPeriod.allCases, id: \.self) { period in
                                Button(action: {
                                    selectedPeriod = period
                                }) {
                                    Text(period.rawValue)
                                        .font(.system(size: 14, weight: selectedPeriod == period ? .bold : .medium))
                                        .foregroundColor(selectedPeriod == period ? .white : .blue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedPeriod == period ? Color.blue : Color.blue.opacity(0.1))
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Summary Cards
                    VStack(spacing: 16) {
                        // Net Amount Card
                        VStack(spacing: 8) {
                            Text("Net Amount")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            Text(currencyManager.format(amount: netAmount))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(netAmount >= 0 ? .green : .red)

                            HStack(spacing: 16) {
                                VStack {
                                    Text("Income")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Text(currencyManager.format(amount: totalReceived))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.green)
                                }

                                Divider().frame(height: 30)

                                VStack {
                                    Text("Expenses")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Text(currencyManager.format(amount: totalSpent))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.regularMaterial)
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                        )

                        // Statistics Grid
                        HStack(spacing: 16) {
                            StatCard(title: "Transactions", value: "\(periodTransactions.count)", icon: "list.bullet", color: .blue)
                            StatCard(title: "Average", value: currencyManager.format(amount: averageTransactionValue), icon: "chart.bar", color: .orange)
                        }

                        HStack(spacing: 16) {
                            StatCard(title: "Completed", value: "\(periodTransactions.filter { $0.status == "completed" }.count)", icon: "checkmark.circle", color: .green)
                            StatCard(title: "Pending", value: "\(periodTransactions.filter { $0.status == "pending" }.count)", icon: "clock", color: .yellow)
                        }
                    }
                    .padding(.horizontal)

                    // Category Breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Category Breakdown")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()

                            Button(action: {
                                showingCategoryBreakdown.toggle()
                            }) {
                                Image(systemName: showingCategoryBreakdown ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            }
                        }

                        if showingCategoryBreakdown {
                            ForEach(categoryBreakdown, id: \.category) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.category.capitalized)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)

                                        Text("\(item.count) transactions")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(currencyManager.format(amount: item.total))
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.primary)

                                        Text(String(format: "%.1f%%", (item.total / totalSpent) * 100))
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Spending Trends
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Spending Trends")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Daily average: \(currencyManager.format(amount: totalSpent / Double(max(Calendar.current.dateComponents([.day], from: periodTransactions.last?.date ?? Date(), to: Date()).day ?? 1, 1))))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        if totalSpent > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(getWeeklyBreakdown(), id: \.week) { item in
                                    HStack {
                                        Text(item.week)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .frame(width: 80, alignment: .leading)

                                        GeometryReader { geometry in
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.blue.opacity(0.7))
                                                .frame(width: geometry.size.width * CGFloat(item.amount / totalSpent))
                                        }
                                        .frame(height: 20)

                                        Text(currencyManager.format(amount: item.amount))
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                            .frame(width: 80, alignment: .trailing)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reports & Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func getWeeklyBreakdown() -> [(week: String, amount: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: periodTransactions) { transaction -> String in
            let weekFormatter = DateFormatter()
            weekFormatter.dateFormat = "MMM d"
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: transaction.date)) ?? transaction.date
            return weekFormatter.string(from: weekStart)
        }

        return grouped.map { (week: $0.key, amount: $0.value.reduce(0) { $0 + $1.total }) }
            .sorted { $0.week < $1.week }
            .suffix(4)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Export Options View

struct ExportOptionsView: View {
    let transactions: [UnifiedTransaction]
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var exportFormat: ExportFormat = .pdf
    @State private var isExporting = false
    @State private var showError = false
    @State private var errorMessage = ""

    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case csv = "CSV"

        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .csv: return "tablecells"
            }
        }

        var description: String {
            switch self {
            case .pdf: return "Professional PDF report with charts"
            case .csv: return "Spreadsheet-compatible format"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Export Format Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Choose Export Format")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal)

                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button(action: {
                            exportFormat = format
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(exportFormat == format ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                        .frame(width: 50, height: 50)

                                    Image(systemName: format.icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(exportFormat == format ? .blue : .gray)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(format.rawValue)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)

                                    Text(format.description)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if exportFormat == format {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(exportFormat == format ? Color.blue : Color.gray.opacity(0.2), lineWidth: exportFormat == format ? 2 : 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(exportFormat == format ? Color.blue.opacity(0.05) : Color.clear)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                }

                Spacer()

                // Export Button
                Button(action: {
                    exportData()
                }) {
                    HStack(spacing: 12) {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "arrow.down.doc.fill")
                        }
                        Text(isExporting ? "Generating..." : "Export \(transactions.count) Transactions")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(gradient: Gradient(colors: isExporting ? [Color.gray, Color.gray.opacity(0.8)] : [Color.green, Color.green.opacity(0.8)]),
                                     startPoint: .leading,
                                     endPoint: .trailing)
                    )
                    .cornerRadius(12)
                    .shadow(color: isExporting ? .gray.opacity(0.3) : .green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isExporting)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isExporting)
                }
            }
            .sheet(isPresented: $showingShareSheet, onDismiss: {
                // Clean up after sharing
                exportURL = nil
            }) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Export Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func exportData() {
        guard !isExporting else { return }

        // Reset previous state
        exportURL = nil
        showError = false

        isExporting = true

        // Generate file on background queue
        DispatchQueue.global(qos: .userInitiated).async {
            let url: URL?

            switch exportFormat {
            case .pdf:
                url = generatePDFReport()
            case .csv:
                url = generateCSV()
            }

            // Update UI on main thread
            DispatchQueue.main.async {
                self.isExporting = false

                if let validURL = url {
                    // Verify file exists
                    if FileManager.default.fileExists(atPath: validURL.path) {
                        self.exportURL = validURL
                        // Small delay to ensure state is updated
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.showingShareSheet = true
                        }
                    } else {
                        self.errorMessage = "Failed to create export file. Please try again."
                        self.showError = true
                    }
                } else {
                    self.errorMessage = "Failed to generate export file. Please try again."
                    self.showError = true
                }
            }
        }
    }

    private func generatePDFReport() -> URL? {
        let timestamp = Date().timeIntervalSince1970
        let fileName = "qassemha_transactions_\(Int(timestamp)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        // Remove old file if exists
        try? FileManager.default.removeItem(at: url)

        let pdfMetaData = [
            kCGPDFContextCreator: "Qassemha",
            kCGPDFContextAuthor: "Transaction History",
            kCGPDFContextTitle: "Transaction Report"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        do {
            let data = renderer.pdfData { context in
                context.beginPage()

                let titleAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)]
                let title = "Transaction History Report"
                title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)

                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .long
                let subtitle = "Generated on \(dateFormatter.string(from: Date()))"
                let subtitleAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)]
                subtitle.draw(at: CGPoint(x: 50, y: 80), withAttributes: subtitleAttributes)

                var yPosition: CGFloat = 120

                for transaction in transactions.prefix(50) {
                    if yPosition > 720 {
                        context.beginPage()
                        yPosition = 50
                    }

                    let transactionText = "\(dateFormatter.string(from: transaction.date)) - \(transaction.title): \(CurrencyManager.shared.format(amount: transaction.total))"
                    let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)]
                    transactionText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: attributes)
                    yPosition += 20
                }
            }

            try data.write(to: url, options: .atomic)

            // Verify file was written
            guard FileManager.default.fileExists(atPath: url.path) else {
                return nil
            }

            return url
        } catch {
            print("Error generating PDF: \(error)")
            return nil
        }
    }

    private func generateCSV() -> URL? {
        let timestamp = Date().timeIntervalSince1970
        let fileName = "qassemha_transactions_\(Int(timestamp)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        // Remove old file if exists
        try? FileManager.default.removeItem(at: url)

        var csvText = "Date,Title,Amount,Currency,Status,Category,Type\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        for transaction in transactions {
            // Escape quotes in title
            let escapedTitle = transaction.title.replacingOccurrences(of: "\"", with: "\"\"")
            let line = "\(dateFormatter.string(from: transaction.date)),\"\(escapedTitle)\",\(transaction.total),\(transaction.currency),\(transaction.status),\(transaction.category),\(transaction.type == .receipt ? "Receipt" : "Transaction")\n"
            csvText.append(line)
        }

        do {
            try csvText.write(to: url, atomically: true, encoding: .utf8)

            // Verify file was written
            guard FileManager.default.fileExists(atPath: url.path) else {
                return nil
            }

            return url
        } catch {
            print("Error generating CSV: \(error)")
            return nil
        }
    }

}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - History Transaction Detail View

struct HistoryTransactionDetailView: View {
    let transaction: UnifiedTransaction
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(transaction.statusColor.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: transaction.typeIcon)
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(transaction.statusColor)
                        }

                        Text(transaction.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        Text(currencyManager.format(amount: transaction.total))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)

                        HStack(spacing: 8) {
                            Circle()
                                .fill(transaction.statusColor)
                                .frame(width: 8, height: 8)

                            Text(transaction.status.capitalized)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(transaction.statusColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(transaction.statusColor.opacity(0.1))
                        )
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                    )

                    // Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Transaction Details")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)

                        HistoryDetailRow(label: "Date", value: formatDate(transaction.date))
                        HistoryDetailRow(label: "Category", value: transaction.category.capitalized)
                        HistoryDetailRow(label: "Type", value: transaction.type == .receipt ? "Receipt" : "Wallet Transaction")

                        if let paymentMethod = transaction.paymentMethod, !paymentMethod.isEmpty {
                            HistoryDetailRow(label: "Payment Method", value: paymentMethod)
                        }

                        HistoryDetailRow(label: "Currency", value: transaction.currency)
                        HistoryDetailRow(label: "Transaction ID", value: transaction.id.uuidString.prefix(8) + "...")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )

                    // Items Section (if available)
                    if !transaction.items.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Items")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)

                            ForEach(transaction.items, id: \.self) { item in
                                HStack {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .foregroundColor(.secondary)

                                    Text(item)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)

                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct HistoryDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
}
