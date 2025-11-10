//
//  WalletView.swift
//  Qassemha
//
//  Digital wallet with balance management and transaction history
//

import SwiftUI

struct WalletView: View {
    @StateObject private var walletManager = WalletManager.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var showingAddFunds = false
    @State private var showingWithdraw = false
    @State private var showingPaymentMethods = false
    @State private var showingTransactionDetail: TransactionModel?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Wallet Balance Card
                    walletBalanceCard

                    // Quick Actions
                    quickActionsSection

                    // Transactions
                    transactionsSection
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingPaymentMethods = true
                    }) {
                        Image(systemName: "creditcard")
                    }
                }
            }
            .sheet(isPresented: $showingAddFunds) {
                AddFundsView(isPresented: $showingAddFunds)
            }
            .sheet(isPresented: $showingWithdraw) {
                WithdrawFundsView(isPresented: $showingWithdraw)
            }
            .sheet(isPresented: $showingPaymentMethods) {
                PaymentMethodsView(isPresented: $showingPaymentMethods)
            }
            .sheet(item: $showingTransactionDetail) { transaction in
                TransactionDetailView(transaction: transaction)
            }
            .onAppear {
                walletManager.refresh()
            }
        }
    }

    // MARK: - Wallet Balance Card

    private var walletBalanceCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wallet Balance")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    Text(currencyManager.format(amount: walletManager.walletBalance))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.cyan]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "plus.circle.fill",
                title: "Add Funds",
                color: .green
            ) {
                showingAddFunds = true
            }

            QuickActionButton(
                icon: "arrow.up.circle.fill",
                title: "Withdraw",
                color: .orange
            ) {
                showingWithdraw = true
            }
        }
    }

    // MARK: - Balances Summary

    private var balancesSummarySection: some View {
        HStack(spacing: 12) {
            BalanceSummaryCard(
                title: "You Owe",
                amount: walletManager.pendingPayments,
                color: .red,
                icon: "arrow.up.circle.fill"
            )

            BalanceSummaryCard(
                title: "You're Owed",
                amount: walletManager.pendingReceipts,
                color: .green,
                icon: "arrow.down.circle.fill"
            )
        }
    }

    // MARK: - Transactions Section

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            if walletManager.transactions.isEmpty {
                WalletEmptyStateView(
                    icon: "arrow.left.arrow.right",
                    message: "No transactions yet"
                )
            } else {
                ForEach(walletManager.transactions.prefix(10)) { transaction in
                    TransactionRow(transaction: transaction)
                        .onTapGesture {
                            showingTransactionDetail = transaction
                        }
                }
            }
        }
    }

}

// MARK: - Supporting Views

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct BalanceSummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    @ObservedObject private var currencyManager = CurrencyManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)

                Spacer()
            }

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            Text(currencyManager.format(amount: amount))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TransactionRow: View {
    let transaction: TransactionModel
    @ObservedObject private var currencyManager = CurrencyManager.shared

    private var icon: String {
        switch transaction.type {
        case "add_funds": return "plus.circle.fill"
        case "withdraw": return "minus.circle.fill"
        case "payment": return "arrow.up.circle.fill"
        case "refund": return "arrow.down.circle.fill"
        default: return "circle.fill"
        }
    }

    private var iconColor: Color {
        switch transaction.type {
        case "add_funds", "refund": return .green
        case "withdraw", "payment": return .red
        default: return .gray
        }
    }

    private var amountPrefix: String {
        switch transaction.type {
        case "add_funds", "refund": return "+"
        case "withdraw", "payment": return "-"
        default: return ""
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.typeDisplay)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text(transaction.description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text(transaction.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(amountPrefix)\(currencyManager.format(amount: transaction.amount))")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(iconColor)

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
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct WalletEmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Add Funds View

struct AddFundsView: View {
    @Binding var isPresented: Bool
    @StateObject private var walletManager = WalletManager.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var amount = ""
    @State private var selectedPaymentMethod: PaymentMethodModel?
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    private let quickAmounts = [10.0, 25.0, 50.0, 100.0, 250.0]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Balance
                    VStack(spacing: 8) {
                        Text("Current Balance")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(currencyManager.format(amount: walletManager.walletBalance))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Amount Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Amount to Add")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        HStack {
                            Text(currencyManager.currencySymbol)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)

                            TextField("0.00", text: $amount)
                                .font(.system(size: 24, weight: .bold))
                                .keyboardType(.decimalPad)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background(Color(.secondarySystemGroupedBackground))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Quick Amount Buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(quickAmounts, id: \.self) { quickAmount in
                                    Button(action: {
                                        amount = String(format: "%.0f", quickAmount)
                                    }) {
                                        Text("\(currencyManager.currencySymbol)\(quickAmount, specifier: "%.0f")")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(.blue, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    }

                    // Payment Method Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payment Method")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        if walletManager.paymentMethods.isEmpty {
                            AddPaymentMethodPrompt()
                        } else {
                            ForEach(walletManager.paymentMethods.prefix(3)) { method in
                                PaymentMethodSelectionRow(
                                    method: method,
                                    isSelected: selectedPaymentMethod?.id == method.id
                                ) {
                                    selectedPaymentMethod = method
                                }
                            }
                        }
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Spacer()

                    // Add Funds Button
                    Button(action: addFunds) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Add \(currencyManager.currencySymbol)\(amount.isEmpty ? "0.00" : amount) to Wallet")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canAddFunds ? Color.green : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!canAddFunds || isProcessing)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .disabled(isProcessing)
                }
            }
            .alert("Funds Added Successfully", isPresented: $showSuccess) {
                Button("Done") {
                    isPresented = false
                }
            } message: {
                Text("$\(amount) has been added to your wallet.")
            }
        }
    }

    private var canAddFunds: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return selectedPaymentMethod != nil
    }

    private func addFunds() {
        guard let amountValue = Double(amount),
              let paymentMethod = selectedPaymentMethod else { return }

        isProcessing = true
        errorMessage = nil

        walletManager.addFunds(amount: amountValue, paymentMethod: paymentMethod) { result in
            isProcessing = false

            switch result {
            case .success:
                showSuccess = true
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Withdraw Funds View

struct WithdrawFundsView: View {
    @Binding var isPresented: Bool
    @StateObject private var walletManager = WalletManager.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var amount = ""
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    private let quickAmounts = [10.0, 25.0, 50.0, 100.0, 250.0]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Balance
                    VStack(spacing: 8) {
                        Text("Available Balance")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(currencyManager.format(amount: walletManager.walletBalance))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Amount Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Amount to Withdraw")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        HStack {
                            Text(currencyManager.currencySymbol)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)

                            TextField("0.00", text: $amount)
                                .font(.system(size: 24, weight: .bold))
                                .keyboardType(.decimalPad)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background(Color(.secondarySystemGroupedBackground))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Quick Amount Buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(quickAmounts.filter { $0 <= walletManager.walletBalance }, id: \.self) { quickAmount in
                                    Button(action: {
                                        amount = String(format: "%.0f", quickAmount)
                                    }) {
                                        Text("\(currencyManager.currencySymbol)\(quickAmount, specifier: "%.0f")")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(.orange, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    }

                    // Withdrawal Info
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)

                        Text("Funds will be transferred to your default bank account within 1-3 business days.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Spacer()

                    // Withdraw Button
                    Button(action: withdrawFunds) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Withdraw $\(amount.isEmpty ? "0.00" : amount)")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canWithdraw ? Color.orange : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!canWithdraw || isProcessing)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Withdraw Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .disabled(isProcessing)
                }
            }
            .alert("Withdrawal Initiated", isPresented: $showSuccess) {
                Button("Done") {
                    isPresented = false
                }
            } message: {
                Text("$\(amount) will be transferred to your bank account within 1-3 business days.")
            }
        }
    }

    private var canWithdraw: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return amountValue <= walletManager.walletBalance
    }

    private func withdrawFunds() {
        guard let amountValue = Double(amount) else { return }

        isProcessing = true
        errorMessage = nil

        walletManager.withdrawFunds(amount: amountValue) { result in
            isProcessing = false

            switch result {
            case .success:
                showSuccess = true
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Payment Methods View

struct PaymentMethodsView: View {
    @Binding var isPresented: Bool
    @StateObject private var walletManager = WalletManager.shared
    @State private var showingAddPaymentMethod = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if walletManager.paymentMethods.isEmpty {
                        WalletEmptyStateView(
                            icon: "creditcard",
                            message: "No payment methods added"
                        )
                        .padding(.top, 40)
                    } else {
                        ForEach(walletManager.paymentMethods) { method in
                            PaymentMethodCard(method: method)
                        }
                    }

                    Button(action: {
                        showingAddPaymentMethod = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium))

                            Text("Add Payment Method")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.blue, lineWidth: 2)
                        )
                    }

                    Spacer()
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Payment Methods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showingAddPaymentMethod) {
                AddPaymentMethodView(isPresented: $showingAddPaymentMethod)
            }
        }
    }
}

// MARK: - Supporting Components

struct PaymentMethodCard: View {
    let method: PaymentMethodModel
    @StateObject private var walletManager = WalletManager.shared

    private var icon: String {
        method.type == "card" ? "creditcard.fill" : "building.columns.fill"
    }

    private var brandColor: Color {
        guard let brand = method.cardBrand?.lowercased() else { return .gray }
        switch brand {
        case "visa": return .blue
        case "mastercard": return .red
        case "amex": return .cyan
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(brandColor.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(brandColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(method.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                if method.type == "card", method.expiryMonth > 0 {
                    Text("Expires \(method.expiryMonth)/\(method.expiryYear)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if method.isDefault {
                Text("Default")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.blue.opacity(0.1))
                    )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            if !method.isDefault {
                Button(action: {
                    walletManager.setDefaultPaymentMethod(method.id)
                }) {
                    Label("Set as Default", systemImage: "checkmark.circle")
                }
            }

            Button(role: .destructive, action: {
                walletManager.removePaymentMethod(method.id)
            }) {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}

struct PaymentMethodSelectionRow: View {
    let method: PaymentMethodModel
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        method.type == "card" ? "creditcard.fill" : "building.columns.fill"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)

                Text(method.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    .background(Color(.secondarySystemGroupedBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct AddPaymentMethodPrompt: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("No payment methods added")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text("Add a payment method to continue")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AddPaymentMethodView: View {
    @Binding var isPresented: Bool
    @StateObject private var walletManager = WalletManager.shared
    @State private var paymentType = "card"
    @State private var cardNumber = ""
    @State private var expiryMonth = ""
    @State private var expiryYear = ""
    @State private var cvv = ""
    @State private var nickname = ""
    @State private var bankName = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Payment Type") {
                    Picker("Type", selection: $paymentType) {
                        Text("Credit/Debit Card").tag("card")
                        Text("Bank Account").tag("bank")
                    }
                    .pickerStyle(.segmented)
                }

                if paymentType == "card" {
                    Section("Card Details") {
                        TextField("Card Number", text: $cardNumber)
                            .keyboardType(.numberPad)

                        HStack {
                            TextField("MM", text: $expiryMonth)
                                .keyboardType(.numberPad)
                                .frame(width: 50)

                            Text("/")

                            TextField("YY", text: $expiryYear)
                                .keyboardType(.numberPad)
                                .frame(width: 50)

                            Spacer()

                            TextField("CVV", text: $cvv)
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                        }

                        TextField("Nickname (Optional)", text: $nickname)
                    }
                } else {
                    Section("Bank Details") {
                        TextField("Bank Name", text: $bankName)
                        TextField("Account Number", text: $cardNumber)
                            .keyboardType(.numberPad)
                        TextField("Nickname (Optional)", text: $nickname)
                    }
                }

                Section {
                    Button("Add Payment Method") {
                        addPaymentMethod()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!canAddMethod)
                }
            }
            .navigationTitle("Add Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private var canAddMethod: Bool {
        if paymentType == "card" {
            return cardNumber.count >= 4 && !expiryMonth.isEmpty && !expiryYear.isEmpty
        } else {
            return !bankName.isEmpty && cardNumber.count >= 4
        }
    }

    private func addPaymentMethod() {
        let lastFour = String(cardNumber.suffix(4))
        let month = Int16(expiryMonth) ?? 0
        let year = Int16(expiryYear) ?? 0

        let method = PaymentMethodModel(
            type: paymentType,
            lastFourDigits: lastFour,
            cardBrand: detectCardBrand(cardNumber),
            bankName: paymentType == "bank" ? bankName : nil,
            expiryMonth: month,
            expiryYear: year,
            nickname: nickname.isEmpty ? nil : nickname
        )

        walletManager.addPaymentMethod(method)
        isPresented = false
    }

    private func detectCardBrand(_ number: String) -> String? {
        guard number.count >= 2 else { return nil }
        let prefix = String(number.prefix(2))

        switch prefix {
        case "4": return "visa"
        case "5": return "mastercard"
        case "3": return "amex"
        default: return "card"
        }
    }
}

struct TransactionDetailView: View {
    let transaction: TransactionModel
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Transaction Icon
                    ZStack {
                        Circle()
                            .fill(transaction.statusColor.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: transactionIcon)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(transaction.statusColor)
                    }

                    // Amount
                    Text(currencyManager.format(amount: transaction.amount))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)

                    // Status
                    HStack(spacing: 8) {
                        Circle()
                            .fill(transaction.statusColor)
                            .frame(width: 8, height: 8)

                        Text(transaction.status.capitalized)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(transaction.statusColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(transaction.statusColor.opacity(0.1))
                    .clipShape(Capsule())

                    // Details
                    VStack(spacing: 0) {
                        DetailRow(title: "Type", value: transaction.typeDisplay)
                        Divider().padding(.leading, 16)
                        DetailRow(title: "Description", value: transaction.description)
                        Divider().padding(.leading, 16)
                        DetailRow(title: "Payment Method", value: transaction.paymentMethod.capitalized)
                        Divider().padding(.leading, 16)
                        DetailRow(title: "Transaction ID", value: transaction.transactionReference)
                        Divider().padding(.leading, 16)
                        DetailRow(title: "Date", value: transaction.createdAt.formatted(date: .long, time: .shortened))

                        if let completedAt = transaction.completedAt {
                            Divider().padding(.leading, 16)
                            DetailRow(title: "Completed At", value: completedAt.formatted(date: .long, time: .shortened))
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var transactionIcon: String {
        switch transaction.type {
        case "add_funds": return "plus.circle.fill"
        case "withdraw": return "minus.circle.fill"
        case "payment": return "arrow.up.circle.fill"
        case "refund": return "arrow.down.circle.fill"
        default: return "circle.fill"
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(16)
    }
}

#Preview {
    WalletView()
}
