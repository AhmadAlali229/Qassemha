//
//  PaymentFlowView.swift
//  Qassemha
//
//  Payment flow for completing bill split payments
//

import SwiftUI

// MARK: - Payment Method Selection View

struct PaymentMethodSelectionView: View {
    @Binding var isPresented: Bool
    @StateObject private var walletManager = WalletManager.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared
    let amount: Double
    let payeeName: String
    let billSplitID: String
    let onPaymentComplete: (PaymentCompletionResult) -> Void

    @State private var selectedMethod: PaymentMethodType = .wallet
    @State private var selectedSavedMethod: PaymentMethodModel?
    @State private var showConfirmation = false
    @State private var notes = ""

    enum PaymentMethodType {
        case wallet
        case cash
        case savedCard
        case externalApp
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Payment Summary Card
                    paymentSummaryCard

                    // Payment Method Options
                    paymentMethodsSection

                    // Notes Section
                    notesSection

                    Spacer()

                    // Pay Button
                    Button(action: {
                        showConfirmation = true
                    }) {
                        Text("Pay \(currencyManager.format(amount: amount))")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(canProceed ? Color.blue : Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!canProceed)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Pay \(payeeName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showConfirmation) {
                PaymentConfirmationView(
                    isPresented: $showConfirmation,
                    amount: amount,
                    payeeName: payeeName,
                    paymentMethod: selectedMethodDisplay,
                    notes: notes,
                    billSplitID: billSplitID,
                    onComplete: { result in
                        showConfirmation = false
                        isPresented = false
                        onPaymentComplete(result)
                    }
                )
            }
        }
    }

    // MARK: - Payment Summary Card

    private var paymentSummaryCard: some View {
        VStack(spacing: 12) {
            Text("Amount Due")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text(currencyManager.format(amount: amount))
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.primary)

            Text("to \(payeeName)")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Payment Methods Section

    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Method")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            // Wallet Option
            PaymentOptionCard(
                icon: "wallet.pass.fill",
                title: "Wallet",
                subtitle: String(format: "Balance: %@", currencyManager.format(amount: walletManager.walletBalance)),
                isSelected: selectedMethod == .wallet,
                isDisabled: walletManager.walletBalance < amount,
                badgeText: walletManager.walletBalance < amount ? "Insufficient funds" : nil
            ) {
                selectedMethod = .wallet
            }

            // Saved Cards
            if !walletManager.paymentMethods.isEmpty {
                ForEach(walletManager.paymentMethods.prefix(2)) { method in
                    PaymentOptionCard(
                        icon: method.type == "card" ? "creditcard.fill" : "building.columns.fill",
                        title: method.displayName,
                        subtitle: method.type == "card" ? "Debit/Credit Card" : "Bank Account",
                        isSelected: selectedMethod == .savedCard && selectedSavedMethod?.id == method.id
                    ) {
                        selectedMethod = .savedCard
                        selectedSavedMethod = method
                    }
                }
            }

            // Cash Option
            PaymentOptionCard(
                icon: "banknote.fill",
                title: "Cash",
                subtitle: "Mark as paid with cash",
                isSelected: selectedMethod == .cash
            ) {
                selectedMethod = .cash
            }

            // External App Option
            PaymentOptionCard(
                icon: "app.fill",
                title: "Other App",
                subtitle: "Venmo, Zelle, etc.",
                isSelected: selectedMethod == .externalApp
            ) {
                selectedMethod = .externalApp
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Note (Optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            TextField("e.g., For dinner", text: $notes)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .background(Color(.secondarySystemGroupedBackground))
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Helper Properties

    /// Validates if payment can proceed with current selection
    /// Checks wallet balance for wallet payments or saved card selection
    private var canProceed: Bool {
        switch selectedMethod {
        case .wallet:
            return walletManager.walletBalance >= amount
        case .savedCard:
            return selectedSavedMethod != nil
        case .cash, .externalApp:
            return true
        }
    }

    /// Returns the display name for the currently selected payment method
    /// Used for confirmation and receipt display
    private var selectedMethodDisplay: String {
        switch selectedMethod {
        case .wallet:
            return "Wallet"
        case .cash:
            return "Cash"
        case .savedCard:
            return selectedSavedMethod?.displayName ?? "Card"
        case .externalApp:
            return "External App"
        }
    }
}

// MARK: - Payment Option Card

struct PaymentOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    var isDisabled: Bool = false
    var badgeText: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .blue : .gray)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Badge or Checkmark
                if let badge = badgeText {
                    Text(badge)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    .background(Color(.secondarySystemGroupedBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .disabled(isDisabled)
    }
}

// MARK: - Payment Confirmation View

struct PaymentConfirmationView: View {
    @Binding var isPresented: Bool
    @StateObject private var walletManager = WalletManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var paymentResult: PaymentCompletionResult?
    @State private var paymentRecordID: UUID?

    let amount: Double
    let payeeName: String
    let paymentMethod: String
    let notes: String
    let billSplitID: String
    let onComplete: (PaymentCompletionResult) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                if isProcessing {
                    processingView
                } else if showSuccess, let result = paymentResult {
                    successView(result: result)
                } else if showError {
                    errorView
                } else {
                    confirmationView
                }
            }
            .padding(20)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Confirm Payment")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Confirmation View

    private var confirmationView: some View {
        VStack(spacing: 32) {
            // Amount
            VStack(spacing: 12) {
                Text("Confirm Payment")
                    .font(.system(size: 24, weight: .bold))

                Text(currencyManager.format(amount: amount))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.blue)
            }

            // Payment Details
            VStack(spacing: 0) {
                DetailRowView(title: "Payment Method", value: paymentMethod)
                Divider().padding(.leading, 16)
                DetailRowView(title: "Amount", value: currencyManager.format(amount: amount))
                if !notes.isEmpty {
                    Divider().padding(.leading, 16)
                    DetailRowView(title: "Note", value: notes)
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button(action: processPayment) {
                    Text("Confirm & Pay")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Processing Payment...")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            Text("Please wait")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Success View

    private func successView(result: PaymentCompletionResult) -> some View {
        VStack(spacing: 24) {
            // Success Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }

            VStack(spacing: 8) {
                Text("Payment Successful!")
                    .font(.system(size: 24, weight: .bold))

                Text(String(format: "%@ paid to %@", currencyManager.format(amount: amount), payeeName))
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Transaction Details
            VStack(spacing: 0) {
                DetailRowView(title: "Transaction ID", value: result.transactionReference)
                Divider().padding(.leading, 16)
                DetailRowView(title: "Payment Method", value: paymentMethod)
                Divider().padding(.leading, 16)
                DetailRowView(title: "Date", value: result.timestamp.formatted(date: .abbreviated, time: .shortened))
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            Button(action: {
                onComplete(result)
            }) {
                Text("Done")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.top, 40)
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: 24) {
            // Error Icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
            }

            VStack(spacing: 8) {
                Text("Payment Failed")
                    .font(.system(size: 24, weight: .bold))

                Text(errorMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: {
                    showError = false
                }) {
                    Text("Try Again")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.top, 40)
    }

    // MARK: - Payment Processing

    /// Processes the payment through the wallet manager
    /// Creates payment record, validates balance, and executes transaction
    private func processPayment() {
        guard let currentUserEmail = authManager.currentUserEmail else {
            errorMessage = "User not found"
            showError = true
            return
        }

        isProcessing = true

        // Check if wallet payment and validate balance
        if paymentMethod == "Wallet" {
            guard walletManager.walletBalance >= amount else {
                isProcessing = false
                errorMessage = "Insufficient wallet balance"
                showError = true
                return
            }
        }

        // Create payment record first
        let dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        let paymentRecord = walletManager.createPaymentRecord(
            billSplitID: billSplitID,
            payerUserID: currentUserEmail,
            payeeUserID: payeeName,
            amount: amount,
            dueDate: dueDate
        )

        paymentRecordID = paymentRecord.id

        // Convert payment method to correct format for WalletManager
        let walletPaymentMethod: String
        switch paymentMethod {
        case "Wallet": walletPaymentMethod = "wallet"
        case "Cash": walletPaymentMethod = "cash"
        case "External App": walletPaymentMethod = "external_app"
        default: walletPaymentMethod = "card"
        }

        // Process payment through WalletManager
        walletManager.processPayment(recordID: paymentRecord.id, paymentMethod: walletPaymentMethod) { result in
            isProcessing = false

            switch result {
            case .success(let transaction):
                let completionResult = PaymentCompletionResult(
                    success: true,
                    transactionReference: transaction.transactionReference,
                    paymentMethod: paymentMethod,
                    amount: amount,
                    timestamp: Date()
                )

                paymentResult = completionResult
                showSuccess = true

            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Detail Row View

struct DetailRowView: View {
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

// MARK: - Payment Completion Result

struct PaymentCompletionResult {
    let success: Bool
    let transactionReference: String
    let paymentMethod: String
    let amount: Double
    let timestamp: Date
}

#Preview {
    PaymentMethodSelectionView(
        isPresented: .constant(true),
        amount: 45.50,
        payeeName: "John Doe",
        billSplitID: "test123",
        onPaymentComplete: { _ in }
    )
}
