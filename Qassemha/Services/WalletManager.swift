//
//  WalletManager.swift
//  Qassemha
//
//  Manages wallet balance, transactions, and payment operations
//

import Foundation
import CoreData
import SwiftUI

class WalletManager: ObservableObject {
    static let shared = WalletManager()

    @Published var walletBalance: Double = 0.0
    @Published var pendingPayments: Double = 0.0
    @Published var pendingReceipts: Double = 0.0
    @Published var transactions: [TransactionModel] = []
    @Published var paymentMethods: [PaymentMethodModel] = []
    @Published var paymentRecords: [PaymentRecordModel] = []

    private let context = PersistenceController.shared.container.viewContext
    private let authManager = AuthenticationManager.shared

    private init() {
        loadWalletData()
    }

    // MARK: - Data Loading

    func loadWalletData() {
        guard let userEmail = authManager.currentUserEmail else { return }

        loadWalletBalance(for: userEmail)
        loadTransactions(for: userEmail)
        loadPaymentMethods(for: userEmail)
        loadPaymentRecords(for: userEmail)
        calculateBalances(for: userEmail)
    }

    private func loadWalletBalance(for userID: String) {
        let request: NSFetchRequest<WalletBalance> = WalletBalance.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userID)

        do {
            let results = try context.fetch(request)
            if let wallet = results.first {
                walletBalance = wallet.balance
            } else {
                // Create new wallet for user
                createWallet(for: userID)
            }
        } catch {
            print("Error loading wallet balance: \(error)")
        }
    }

    private func createWallet(for userID: String) {
        let wallet = WalletBalance(context: context)
        wallet.walletID = UUID()
        wallet.userID = userID
        wallet.balance = 0.0
        wallet.currency = CurrencyManager.shared.currencyCode
        wallet.lastUpdated = Date()

        saveContext()
        walletBalance = 0.0
    }

    private func loadTransactions(for userID: String) {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userID)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            let results = try context.fetch(request)
            transactions = results.map { TransactionModel(from: $0) }
        } catch {
            print("Error loading transactions: \(error)")
        }
    }

    private func loadPaymentMethods(for userID: String) {
        let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userID)
        request.sortDescriptors = [NSSortDescriptor(key: "isDefault", ascending: false),
                                   NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            let results = try context.fetch(request)
            paymentMethods = results.map { PaymentMethodModel(from: $0) }
        } catch {
            print("Error loading payment methods: \(error)")
        }
    }

    private func loadPaymentRecords(for userID: String) {
        let request: NSFetchRequest<PaymentRecord> = PaymentRecord.fetchRequest()
        let predicate = NSPredicate(format: "payerUserID == %@ OR payeeUserID == %@", userID, userID)
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            let results = try context.fetch(request)
            paymentRecords = results.map { PaymentRecordModel(from: $0) }
        } catch {
            print("Error loading payment records: \(error)")
        }
    }

    private func calculateBalances(for userID: String) {
        // Calculate pending payments (what you owe)
        pendingPayments = paymentRecords
            .filter { $0.payerUserID == userID && $0.status == "pending" }
            .reduce(0.0) { $0 + $1.amount }

        // Calculate pending receipts (what you're owed)
        pendingReceipts = paymentRecords
            .filter { $0.payeeUserID == userID && $0.status == "pending" }
            .reduce(0.0) { $0 + $1.amount }
    }

    // MARK: - Transaction Retrieval

    func getAllTransactions() -> [TransactionModel] {
        return transactions
    }

    // MARK: - Wallet Operations

    func addFunds(amount: Double, paymentMethod: PaymentMethodModel, completion: @escaping (Result<TransactionModel, Error>) -> Void) {
        guard let userID = authManager.currentUserEmail else {
            completion(.failure(WalletError.userNotFound))
            return
        }

        // Simulate transaction processing
        let transaction = createTransaction(
            userID: userID,
            type: "add_funds",
            amount: amount,
            paymentMethod: paymentMethod.type,
            description: "Added funds to wallet"
        )

        // Simulate async processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }

            // Complete transaction
            self.completeTransaction(transaction.id)

            // Update wallet balance
            self.updateWalletBalance(userID: userID, amount: amount, isAddition: true)

            completion(.success(transaction))
        }
    }

    func withdrawFunds(amount: Double, completion: @escaping (Result<TransactionModel, Error>) -> Void) {
        guard let userID = authManager.currentUserEmail else {
            completion(.failure(WalletError.userNotFound))
            return
        }

        guard walletBalance >= amount else {
            completion(.failure(WalletError.insufficientFunds))
            return
        }

        // Create withdrawal transaction
        let transaction = createTransaction(
            userID: userID,
            type: "withdraw",
            amount: amount,
            paymentMethod: "bank_transfer",
            description: "Withdrew funds from wallet"
        )

        // Simulate async processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }

            // Complete transaction
            self.completeTransaction(transaction.id)

            // Update wallet balance
            self.updateWalletBalance(userID: userID, amount: amount, isAddition: false)

            completion(.success(transaction))
        }
    }

    func deductFromWallet(amount: Double) {
        guard let userID = authManager.currentUserEmail else { return }
        updateWalletBalance(userID: userID, amount: amount, isAddition: false)
    }

    func recordReceivedPayment(from participantName: String, amount: Double, storeName: String, receiptId: UUID) {
        guard let userID = authManager.currentUserEmail else { return }

        // Add to wallet balance
        updateWalletBalance(userID: userID, amount: amount, isAddition: true)

        // Create transaction for received payment
        _ = createTransaction(
            userID: userID,
            type: "received",
            amount: amount,
            paymentMethod: "bill_split",
            description: "Received from \(participantName) for \(storeName)",
            billSplitID: receiptId.uuidString
        )
    }

    private func updateWalletBalance(userID: String, amount: Double, isAddition: Bool) {
        let request: NSFetchRequest<WalletBalance> = WalletBalance.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userID)

        do {
            let results = try context.fetch(request)
            if let wallet = results.first {
                wallet.balance += isAddition ? amount : -amount
                wallet.lastUpdated = Date()
                saveContext()
                walletBalance = wallet.balance
            }
        } catch {
            print("Error updating wallet balance: \(error)")
        }
    }

    // MARK: - Transaction Management

    func createTransaction(
        userID: String,
        type: String,
        amount: Double,
        paymentMethod: String,
        description: String,
        billSplitID: String? = nil
    ) -> TransactionModel {
        let transaction = Transaction(context: context)
        transaction.transactionID = UUID()
        transaction.userID = userID
        transaction.type = type
        transaction.amount = amount
        transaction.currency = CurrencyManager.shared.currencyCode

        // Set status based on transaction type
        // Received payments, refunds, and add_funds are completed immediately
        if type == "received" || type == "add_funds" || type == "refund" {
            transaction.status = "completed"
            transaction.completedAt = Date()
        } else {
            transaction.status = "pending"
        }

        transaction.paymentMethod = paymentMethod
        transaction.transactionReference = generateTransactionReference()
        transaction.transactionDescription = description
        transaction.relatedBillSplitID = billSplitID
        transaction.createdAt = Date()

        saveContext()

        let model = TransactionModel(from: transaction)
        transactions.insert(model, at: 0)

        return model
    }

    private func completeTransaction(_ transactionID: UUID) {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.predicate = NSPredicate(format: "transactionID == %@", transactionID as CVarArg)

        do {
            let results = try context.fetch(request)
            if let transaction = results.first, let userID = transaction.userID {
                transaction.status = "completed"
                transaction.completedAt = Date()
                saveContext()
                loadTransactions(for: userID)
            }
        } catch {
            print("Error completing transaction: \(error)")
        }
    }

    private func generateTransactionReference() -> String {
        let prefix = "TXN"
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let random = String(format: "%04d", Int.random(in: 0...9999))
        return "\(prefix)\(timestamp)\(random)"
    }

    // MARK: - Payment Method Management

    func addPaymentMethod(_ method: PaymentMethodModel) {
        guard let userID = authManager.currentUserEmail else { return }

        let paymentMethod = PaymentMethod(context: context)
        paymentMethod.paymentMethodID = UUID()
        paymentMethod.userID = userID
        paymentMethod.type = method.type
        paymentMethod.lastFourDigits = method.lastFourDigits
        paymentMethod.cardBrand = method.cardBrand
        paymentMethod.bankName = method.bankName
        paymentMethod.expiryMonth = method.expiryMonth
        paymentMethod.expiryYear = method.expiryYear
        paymentMethod.isDefault = paymentMethods.isEmpty // First payment method is default
        paymentMethod.nickname = method.nickname
        paymentMethod.createdAt = Date()

        saveContext()
        loadPaymentMethods(for: userID)
    }

    func removePaymentMethod(_ methodID: UUID) {
        let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
        request.predicate = NSPredicate(format: "paymentMethodID == %@", methodID as CVarArg)

        do {
            let results = try context.fetch(request)
            if let method = results.first {
                context.delete(method)
                saveContext()

                if let userID = authManager.currentUserEmail {
                    loadPaymentMethods(for: userID)
                }
            }
        } catch {
            print("Error removing payment method: \(error)")
        }
    }

    func setDefaultPaymentMethod(_ methodID: UUID) {
        guard let userID = authManager.currentUserEmail else { return }

        let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userID)

        do {
            let methods = try context.fetch(request)
            for method in methods {
                method.isDefault = (method.paymentMethodID == methodID)
            }
            saveContext()
            loadPaymentMethods(for: userID)
        } catch {
            print("Error setting default payment method: \(error)")
        }
    }

    // MARK: - Payment Record Management

    func createPaymentRecord(
        billSplitID: String,
        payerUserID: String,
        payeeUserID: String,
        amount: Double,
        dueDate: Date?
    ) -> PaymentRecordModel {
        let record = PaymentRecord(context: context)
        let recordID = UUID()
        record.paymentRecordID = recordID
        record.billSplitID = billSplitID
        record.payerUserID = payerUserID
        record.payeeUserID = payeeUserID
        record.amount = amount
        record.currency = CurrencyManager.shared.currencyCode
        record.paymentMethod = "pending"
        record.status = "pending"
        record.dueDate = dueDate
        record.createdAt = Date()

        saveContext()

        let model = PaymentRecordModel(from: record)
        paymentRecords.insert(model, at: 0)

        if let userID = authManager.currentUserEmail {
            calculateBalances(for: userID)
        }

        // Schedule payment reminder if due date is set
        if let dueDate = dueDate {
            let preferences = NotificationPreferences.load()
            if preferences.enabled {
                let schedule: ReminderSchedule
                switch preferences.reminderSchedule {
                case "oneDayBefore": schedule = .oneDayBefore
                case "threeDaysBefore": schedule = .threeDaysBefore
                case "oneWeekBefore": schedule = .oneWeekBefore
                default: schedule = .multipleDays
                }

                NotificationManager.shared.schedulePaymentReminder(
                    paymentRecordID: recordID,
                    payeeName: payeeUserID,
                    amount: amount,
                    dueDate: dueDate,
                    reminderSchedule: schedule
                )
            }
        }

        // Update badge count
        NotificationManager.shared.updateBadgeCount()

        return model
    }

    func processPayment(
        recordID: UUID,
        paymentMethod: String,
        completion: @escaping (Result<TransactionModel, Error>) -> Void
    ) {
        guard let userID = authManager.currentUserEmail else {
            completion(.failure(WalletError.userNotFound))
            return
        }

        // Find payment record
        let request: NSFetchRequest<PaymentRecord> = PaymentRecord.fetchRequest()
        request.predicate = NSPredicate(format: "paymentRecordID == %@", recordID as CVarArg)

        do {
            let results = try context.fetch(request)
            guard let record = results.first else {
                completion(.failure(WalletError.recordNotFound))
                return
            }

            // Check if wallet payment and sufficient funds
            if paymentMethod == "wallet" {
                guard walletBalance >= record.amount else {
                    completion(.failure(WalletError.insufficientFunds))
                    return
                }
            }

            // Create transaction
            let transaction = createTransaction(
                userID: userID,
                type: "payment",
                amount: record.amount,
                paymentMethod: paymentMethod,
                description: "Payment for bill split",
                billSplitID: record.billSplitID
            )

            // Simulate processing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self = self else { return }

                // Update payment record
                record.status = "completed"
                record.paymentMethod = paymentMethod
                record.transactionID = transaction.transactionReference
                record.paidAt = Date()

                // Deduct from wallet if wallet payment
                if paymentMethod == "wallet" {
                    self.updateWalletBalance(userID: userID, amount: record.amount, isAddition: false)
                }

                // Complete transaction
                self.completeTransaction(transaction.id)

                // Cancel payment reminders for this record
                NotificationManager.shared.cancelPaymentReminders(for: recordID)

                // Update badge count
                NotificationManager.shared.updateBadgeCount()

                self.saveContext()
                self.loadPaymentRecords(for: userID)
                self.calculateBalances(for: userID)

                completion(.success(transaction))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func receivePayment(recordID: UUID) {
        guard let userID = authManager.currentUserEmail else { return }

        let request: NSFetchRequest<PaymentRecord> = PaymentRecord.fetchRequest()
        request.predicate = NSPredicate(format: "paymentRecordID == %@", recordID as CVarArg)

        do {
            let results = try context.fetch(request)
            if let record = results.first {
                // Mark as completed
                record.status = "completed"
                record.paidAt = Date()

                // Add to wallet balance
                updateWalletBalance(userID: userID, amount: record.amount, isAddition: true)

                // Create transaction
                _ = createTransaction(
                    userID: userID,
                    type: "refund",
                    amount: record.amount,
                    paymentMethod: record.paymentMethod ?? "unknown",
                    description: "Received payment for bill split",
                    billSplitID: record.billSplitID
                )

                saveContext()
                loadPaymentRecords(for: userID)
                calculateBalances(for: userID)
            }
        } catch {
            print("Error receiving payment: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }

    func refresh() {
        if let userID = authManager.currentUserEmail {
            loadWalletData()
        }
    }

    // MARK: - Example Data

    func createExampleWalletEntries() {
        guard let userID = authManager.currentUserEmail else { return }

        var totalAmountToAdd: Double = 0
        var shouldCheckBalance = false

        // Check if Chris's transaction exists
        let chrisRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        chrisRequest.predicate = NSPredicate(format: "transactionID == %@", UUID(uuidString: "50000000-0000-0000-0000-000000000001")! as CVarArg)

        // Chris's share calculation:
        // - Movie ticket: $50.00 / 4 = $12.50
        // - Popcorn: $16.00 / 2 = $8.00
        // - Soda: $22.00 / 4 = $5.50
        // - Subtotal: $26.00
        // - Tax (proportional): $7.56 * (26.00/94.50) = $2.08
        // - Total: $28.08
        let chrisAmount = 28.08

        do {
            let results = try context.fetch(chrisRequest)
            if let existingTransaction = results.first {
                // Transaction exists, mark that we should verify wallet balance
                shouldCheckBalance = true
                // Update existing transaction if amount is wrong
                if existingTransaction.amount != chrisAmount {
                    let oldAmount = existingTransaction.amount
                    existingTransaction.amount = chrisAmount
                    existingTransaction.transactionDescription = "Received from Chris for CineMax Theater"
                    // Adjust wallet balance for the difference
                    totalAmountToAdd += (chrisAmount - oldAmount)
                }
            } else {
                // Create new transaction
                let chrisPayment = Transaction(context: context)
                chrisPayment.transactionID = UUID(uuidString: "50000000-0000-0000-0000-000000000001")!
                chrisPayment.userID = userID
                chrisPayment.type = "received"
                chrisPayment.amount = chrisAmount
                chrisPayment.currency = CurrencyManager.shared.currencyCode
                chrisPayment.status = "completed"
                chrisPayment.paymentMethod = "bill_split"
                chrisPayment.transactionReference = "TXN" + String(Int(Date().timeIntervalSince1970)) + "0001"
                chrisPayment.transactionDescription = "Received from Chris for CineMax Theater"
                chrisPayment.relatedBillSplitID = "00000000-0000-0000-0000-000000000004"
                chrisPayment.createdAt = Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
                chrisPayment.completedAt = Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()

                totalAmountToAdd += chrisAmount
            }
        } catch {
            print("Error checking for Chris's transaction: \(error)")
        }

        // Check if Sam's transaction exists
        let samRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        samRequest.predicate = NSPredicate(format: "transactionID == %@", UUID(uuidString: "50000000-0000-0000-0000-000000000002")! as CVarArg)

        // Sam's share calculation (same as Chris):
        // - Movie ticket: $50.00 / 4 = $12.50
        // - Popcorn: $16.00 / 2 = $8.00
        // - Soda: $22.00 / 4 = $5.50
        // - Subtotal: $26.00
        // - Tax (proportional): $7.56 * (26.00/94.50) = $2.08
        // - Total: $28.08
        let samAmount = 28.08

        do {
            let results = try context.fetch(samRequest)
            if let existingTransaction = results.first {
                // Transaction exists, mark that we should verify wallet balance
                shouldCheckBalance = true
                // Update existing transaction if amount is wrong
                if existingTransaction.amount != samAmount {
                    let oldAmount = existingTransaction.amount
                    existingTransaction.amount = samAmount
                    existingTransaction.transactionDescription = "Received from Sam for CineMax Theater"
                    // Adjust wallet balance for the difference
                    totalAmountToAdd += (samAmount - oldAmount)
                }
            } else {
                // Create new transaction
                let samPayment = Transaction(context: context)
                samPayment.transactionID = UUID(uuidString: "50000000-0000-0000-0000-000000000002")!
                samPayment.userID = userID
                samPayment.type = "received"
                samPayment.amount = samAmount
                samPayment.currency = CurrencyManager.shared.currencyCode
                samPayment.status = "completed"
                samPayment.paymentMethod = "bill_split"
                samPayment.transactionReference = "TXN" + String(Int(Date().timeIntervalSince1970)) + "0002"
                samPayment.transactionDescription = "Received from Sam for CineMax Theater"
                samPayment.relatedBillSplitID = "00000000-0000-0000-0000-000000000004"
                samPayment.createdAt = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
                samPayment.completedAt = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()

                totalAmountToAdd += samAmount
            }
        } catch {
            print("Error checking for Sam's transaction: \(error)")
        }

        // Save and update balance if we created or updated transactions
        if totalAmountToAdd != 0 {
            saveContext()
            loadTransactions(for: userID)
            updateWalletBalance(userID: userID, amount: abs(totalAmountToAdd), isAddition: totalAmountToAdd > 0)
        } else if shouldCheckBalance {
            // Transactions exist but balance might be wrong - verify it
            let expectedBalance = chrisAmount + samAmount  // 28.08 + 28.08 = 56.16

            // Check current wallet balance
            let request: NSFetchRequest<WalletBalance> = WalletBalance.fetchRequest()
            request.predicate = NSPredicate(format: "userID == %@", userID)

            do {
                let results = try context.fetch(request)
                if let wallet = results.first {
                    // If wallet balance is incorrect, fix it
                    if wallet.balance != expectedBalance {
                        print("⚠️ Wallet balance mismatch. Expected: \(expectedBalance), Actual: \(wallet.balance). Correcting...")
                        wallet.balance = expectedBalance
                        wallet.lastUpdated = Date()
                        saveContext()
                        walletBalance = expectedBalance
                    }
                }
            } catch {
                print("Error checking wallet balance: \(error)")
            }
        }
    }
}

// MARK: - Models

struct TransactionModel: Identifiable {
    let id: UUID
    let userID: String
    let type: String
    let amount: Double
    let currency: String
    let status: String
    let paymentMethod: String
    let transactionReference: String
    let description: String
    let relatedBillSplitID: String?
    let createdAt: Date
    let completedAt: Date?

    init(from entity: Transaction) {
        self.id = entity.transactionID ?? UUID()
        self.userID = entity.userID ?? ""
        self.type = entity.type ?? ""
        self.amount = entity.amount
        self.currency = entity.currency ?? "USD"
        self.status = entity.status ?? "pending"
        self.paymentMethod = entity.paymentMethod ?? ""
        self.transactionReference = entity.transactionReference ?? ""
        self.description = entity.transactionDescription ?? ""
        self.relatedBillSplitID = entity.relatedBillSplitID
        self.createdAt = entity.createdAt ?? Date()
        self.completedAt = entity.completedAt
    }

    var typeDisplay: String {
        switch type {
        case "add_funds": return "Add Funds"
        case "withdraw": return "Withdraw"
        case "payment": return "Payment"
        case "refund": return "Received"
        case "received": return "Received"
        default: return type.capitalized
        }
    }

    var statusColor: Color {
        switch status {
        case "completed": return .green
        case "pending": return .orange
        case "failed": return .red
        default: return .gray
        }
    }
}

struct PaymentMethodModel: Identifiable {
    let id: UUID
    let userID: String
    let type: String
    let lastFourDigits: String
    let cardBrand: String?
    let bankName: String?
    let expiryMonth: Int16
    let expiryYear: Int16
    let isDefault: Bool
    let nickname: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        userID: String = "",
        type: String,
        lastFourDigits: String,
        cardBrand: String? = nil,
        bankName: String? = nil,
        expiryMonth: Int16 = 0,
        expiryYear: Int16 = 0,
        isDefault: Bool = false,
        nickname: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userID = userID
        self.type = type
        self.lastFourDigits = lastFourDigits
        self.cardBrand = cardBrand
        self.bankName = bankName
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.isDefault = isDefault
        self.nickname = nickname
        self.createdAt = createdAt
    }

    init(from entity: PaymentMethod) {
        self.id = entity.paymentMethodID ?? UUID()
        self.userID = entity.userID ?? ""
        self.type = entity.type ?? ""
        self.lastFourDigits = entity.lastFourDigits ?? ""
        self.cardBrand = entity.cardBrand
        self.bankName = entity.bankName
        self.expiryMonth = entity.expiryMonth
        self.expiryYear = entity.expiryYear
        self.isDefault = entity.isDefault
        self.nickname = entity.nickname
        self.createdAt = entity.createdAt ?? Date()
    }

    var displayName: String {
        if let nickname = nickname {
            return nickname
        }

        if type == "card", let brand = cardBrand {
            return "\(brand.capitalized) •••• \(lastFourDigits)"
        } else if type == "bank", let bank = bankName {
            return "\(bank) •••• \(lastFourDigits)"
        }

        return "•••• \(lastFourDigits)"
    }
}

struct PaymentRecordModel: Identifiable {
    let id: UUID
    let billSplitID: String
    let payerUserID: String
    let payeeUserID: String
    let amount: Double
    let currency: String
    let paymentMethod: String
    let status: String
    let transactionID: String?
    let dueDate: Date?
    let paidAt: Date?
    let notes: String?
    let createdAt: Date

    init(from entity: PaymentRecord) {
        self.id = entity.paymentRecordID ?? UUID()
        self.billSplitID = entity.billSplitID ?? ""
        self.payerUserID = entity.payerUserID ?? ""
        self.payeeUserID = entity.payeeUserID ?? ""
        self.amount = entity.amount
        self.currency = entity.currency ?? "USD"
        self.paymentMethod = entity.paymentMethod ?? ""
        self.status = entity.status ?? "pending"
        self.transactionID = entity.transactionID
        self.dueDate = entity.dueDate
        self.paidAt = entity.paidAt
        self.notes = entity.notes
        self.createdAt = entity.createdAt ?? Date()
    }

    var statusColor: Color {
        switch status {
        case "completed": return .green
        case "pending": return .orange
        case "failed": return .red
        case "cancelled": return .gray
        default: return .gray
        }
    }

    var isOverdue: Bool {
        guard let dueDate = dueDate, status == "pending" else { return false }
        return dueDate < Date()
    }
}

// MARK: - Errors

enum WalletError: LocalizedError {
    case userNotFound
    case insufficientFunds
    case recordNotFound
    case transactionFailed

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .insufficientFunds:
            return "Insufficient wallet balance"
        case .recordNotFound:
            return "Payment record not found"
        case .transactionFailed:
            return "Transaction failed"
        }
    }
}
