//
//  WalletView.swift
//  Qassemha
//
//  Created by Harjot Singh on 21/09/25.
//

import SwiftUI

struct WalletView: View {
    @State private var walletBalance: Double = 248.50
    @State private var pendingPayments: Double = 67.25
    @State private var showingAddFunds = false
    @State private var showingPaymentMethods = false

    // Sample payment methods
    private let paymentMethods = [
        PaymentMethod(id: 1, type: "card", name: "•••• 1234", brand: "Visa", isDefault: true),
        PaymentMethod(id: 2, type: "card", name: "•••• 5678", brand: "Mastercard", isDefault: false),
        PaymentMethod(id: 3, type: "bank", name: "Chase ••••9876", brand: "Bank", isDefault: false)
    ]

    // Sample recent transactions
    private let recentTransactions = [
        WalletTransaction(id: 1, type: "payment", description: "Paid Sarah for dinner", amount: -23.50, date: "Today", status: "completed"),
        WalletTransaction(id: 2, type: "received", description: "Received from Mike", amount: 45.00, date: "Yesterday", status: "completed"),
        WalletTransaction(id: 3, type: "topup", description: "Added funds", amount: 100.00, date: "2 days ago", status: "completed"),
        WalletTransaction(id: 4, type: "payment", description: "Coffee with friends", amount: -12.75, date: "3 days ago", status: "pending")
    ]

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "wallet.pass")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("Wallet")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Coming Soon")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.05),
                        Color.cyan.opacity(0.02),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct PaymentMethod: Identifiable {
    let id: Int
    let type: String
    let name: String
    let brand: String
    let isDefault: Bool
}

struct WalletTransaction: Identifiable {
    let id: Int
    let type: String
    let description: String
    let amount: Double
    let date: String
    let status: String
}

struct PaymentMethodCard: View {
    let method: PaymentMethod

    private var icon: String {
        switch method.type {
        case "card":
            return "creditcard.fill"
        case "bank":
            return "building.columns.fill"
        default:
            return "wallet.pass.fill"
        }
    }

    private var brandColor: Color {
        switch method.brand.lowercased() {
        case "visa":
            return .blue
        case "mastercard":
            return .red
        default:
            return .gray
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
                Text(method.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(method.brand)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct WalletTransactionCard: View {
    let transaction: WalletTransaction

    private var icon: String {
        switch transaction.type {
        case "payment":
            return "arrow.up.circle.fill"
        case "received":
            return "arrow.down.circle.fill"
        case "topup":
            return "plus.circle.fill"
        default:
            return "circle.fill"
        }
    }

    private var iconColor: Color {
        switch transaction.type {
        case "payment":
            return .red
        case "received":
            return .green
        case "topup":
            return .blue
        default:
            return .gray
        }
    }

    private var amountColor: Color {
        return transaction.amount >= 0 ? .green : .primary
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(transaction.date)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.amount >= 0 ? "+$\(transaction.amount, specifier: "%.2f")" : "-$\(abs(transaction.amount), specifier: "%.2f")")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(amountColor)

                if transaction.status == "pending" {
                    Text("Pending")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct AddFundsView: View {
    @Binding var isPresented: Bool
    @Binding var currentBalance: Double
    @State private var amount = ""
    @State private var selectedMethod = 0

    private let quickAmounts = [10.0, 25.0, 50.0, 100.0]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Current Balance
                VStack(spacing: 8) {
                    Text("Current Balance")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("$\(currentBalance, specifier: "%.2f")")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                }

                // Amount Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Amount to Add")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    HStack {
                        Text("$")
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
                    )

                    // Quick Amount Buttons
                    HStack(spacing: 12) {
                        ForEach(quickAmounts, id: \.self) { quickAmount in
                            Button(action: {
                                amount = String(format: "%.0f", quickAmount)
                            }) {
                                Text("$\(quickAmount, specifier: "%.0f")")
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

                Spacer()

                // Add Funds Button
                Button(action: {
                    if let amountValue = Double(amount) {
                        currentBalance += amountValue
                        isPresented = false
                    }
                }) {
                    Text("Add Funds")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(amount.isEmpty || Double(amount) == nil || Double(amount)! <= 0)
            }
            .padding(20)
            .navigationTitle("Add Funds")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct PaymentMethodsView: View {
    @Binding var isPresented: Bool
    let paymentMethods: [PaymentMethod]

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                ForEach(paymentMethods) { method in
                    PaymentMethodCard(method: method)
                }

                Button(action: {
                    // Add new payment method
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
            .navigationTitle("Payment Methods")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    WalletView()
}