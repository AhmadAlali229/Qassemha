//
//  NotificationManager.swift
//  Qassemha
//
//  Manages local notifications for payment reminders
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    @Published var notificationPermissionGranted = false

    private let notificationCenter = UNUserNotificationCenter.current()

    /// Initializes the singleton NotificationManager and sets up notification delegate
    /// Ensures notification permissions are checked on creation to prevent unauthorized access
    private override init() {
        super.init()
        notificationCenter.delegate = self
        checkNotificationPermission()
    }

    // MARK: - Permission Management

    /// Requests notification permission from the user with alert, badge, and sound options
    /// Provides callback with granted status to enable immediate UI updates and feature gating
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = granted

                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                }

                completion(granted)
            }
        }
    }

    /// Checks current notification authorization status and updates published property
    /// Allows app to determine if notification features should be enabled without prompting user
    func checkNotificationPermission() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Payment Reminders

    /// Schedules local notifications for payment reminders based on due date and schedule type
    /// Supports multiple reminder times and includes payment details for user context
    func schedulePaymentReminder(
        paymentRecordID: UUID,
        payeeName: String,
        amount: Double,
        dueDate: Date,
        reminderSchedule: ReminderSchedule = .oneDayBefore,
        restaurantName: String? = nil
    ) {
        guard notificationPermissionGranted else {
            print("Notification permission not granted")
            return
        }

        // Calculate notification dates based on schedule
        let notificationDates = calculateNotificationDates(from: dueDate, schedule: reminderSchedule)

        for (index, date) in notificationDates.enumerated() {
            guard date > Date() else { continue } // Skip past dates

            let content = UNMutableNotificationContent()
            content.title = "Payment Reminder"

            // Format message based on whether restaurant name is provided
            let formattedAmount = CurrencyManager.shared.format(amount: amount)
            if let restaurant = restaurantName {
                content.body = "\(restaurant) - \(payeeName)'s payment of \(formattedAmount) is pending"
            } else {
                content.body = "\(payeeName)'s payment of \(formattedAmount) is pending"
            }

            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "PAYMENT_REMINDER"
            content.userInfo = [
                "paymentRecordID": paymentRecordID.uuidString,
                "amount": amount,
                "payeeName": payeeName,
                "restaurantName": restaurantName ?? ""
            ]

            // Create trigger
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

            // Create request
            let identifier = "payment_\(paymentRecordID.uuidString)_\(index)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            // Schedule notification
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    print("Scheduled payment reminder for \(date)")
                }
            }
        }
    }

    /// Schedules immediate notification for overdue payments with critical alert sound
    /// Emphasizes urgency by showing how many days past due and using critical sound
    func scheduleOverduePaymentReminder(
        paymentRecordID: UUID,
        payeeName: String,
        amount: Double,
        daysPastDue: Int,
        restaurantName: String? = nil
    ) {
        guard notificationPermissionGranted else { return }

        let content = UNMutableNotificationContent()
        content.title = "Overdue Payment"

        // Format message based on whether restaurant name is provided
        let formattedAmount = CurrencyManager.shared.format(amount: amount)
        if let restaurant = restaurantName {
            content.body = "\(restaurant) - \(payeeName)'s payment of \(formattedAmount) is \(daysPastDue) day\(daysPastDue == 1 ? "" : "s") overdue"
        } else {
            content.body = "\(payeeName)'s payment of \(formattedAmount) is \(daysPastDue) day\(daysPastDue == 1 ? "" : "s") overdue"
        }

        content.sound = .defaultCritical
        content.badge = 1
        content.categoryIdentifier = "OVERDUE_PAYMENT"
        content.userInfo = [
            "paymentRecordID": paymentRecordID.uuidString,
            "amount": amount,
            "payeeName": payeeName,
            "daysPastDue": daysPastDue,
            "restaurantName": restaurantName ?? ""
        ]

        // Schedule for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "overdue_\(paymentRecordID.uuidString)_\(daysPastDue)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling overdue notification: \(error.localizedDescription)")
            }
        }
    }

    /// Cancels all pending notification reminders associated with a specific payment record
    /// Prevents unnecessary notifications when payment is completed or cancelled
    func cancelPaymentReminders(for paymentRecordID: UUID) {
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.contains(paymentRecordID.uuidString) }
                .map { $0.identifier }

            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            print("Cancelled \(identifiersToRemove.count) reminders for payment \(paymentRecordID)")
        }
    }

    /// Removes all pending payment reminder notifications from the notification center
    /// Useful for resetting notification state or when user logs out
    func cancelAllPaymentReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Helper Methods

    /// Calculates notification dates based on due date and reminder schedule type
    /// Preserves user-selected time of day for reminders to match their preferences
    private func calculateNotificationDates(from dueDate: Date, schedule: ReminderSchedule) -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current

        // Extract time components from the user-selected due date
        let timeComponents = calendar.dateComponents([.hour, .minute], from: dueDate)
        let hour = timeComponents.hour ?? 9
        let minute = timeComponents.minute ?? 0

        switch schedule {
        case .oneDayBefore:
            if let date = calendar.date(byAdding: .day, value: -1, to: dueDate),
               let dateWithTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
                dates.append(dateWithTime)
            }

        case .threeDaysBefore:
            if let date = calendar.date(byAdding: .day, value: -3, to: dueDate),
               let dateWithTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
                dates.append(dateWithTime)
            }

        case .oneWeekBefore:
            if let date = calendar.date(byAdding: .day, value: -7, to: dueDate),
               let dateWithTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
                dates.append(dateWithTime)
            }

        case .multipleDays:
            // 7 days, 3 days, and 1 day before (all at the user-selected time)
            for days in [7, 3, 1] {
                if let date = calendar.date(byAdding: .day, value: -days, to: dueDate),
                   let dateWithTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
                    dates.append(dateWithTime)
                }
            }

        case .custom(let daysBefore):
            for days in daysBefore.sorted(by: >) {
                if let date = calendar.date(byAdding: .day, value: -days, to: dueDate),
                   let dateWithTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
                    dates.append(dateWithTime)
                }
            }
        }

        // Add on due date reminder at the user-selected time
        if let dueDateWithTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: dueDate) {
            dates.append(dueDateWithTime)
        }

        return dates.filter { $0 > Date() } // Only return future dates
    }

    // MARK: - Overdue Payment Scanning

    /// Scans wallet payment records for overdue payments and schedules escalating reminders
    /// Sends reminders every 3 days for overdue payments to ensure they're not forgotten
    func checkForOverduePayments() {
        let walletManager = WalletManager.shared
        let calendar = Calendar.current

        for record in walletManager.paymentRecords {
            guard record.status == "pending",
                  let dueDate = record.dueDate else { continue }

            // Check if overdue
            if dueDate < Date() {
                let days = calendar.dateComponents([.day], from: dueDate, to: Date()).day ?? 0

                if days > 0 {
                    // Schedule escalating reminders (every 3 days for overdue)
                    if days % 3 == 0 {
                        scheduleOverduePaymentReminder(
                            paymentRecordID: record.id,
                            payeeName: record.payeeUserID,
                            amount: record.amount,
                            daysPastDue: days
                        )
                    }
                }
            }
        }
    }

    // MARK: - Notification Actions

    /// Configures notification action buttons for payment reminders (Pay Now, Snooze)
    /// Allows users to interact with notifications without opening the app
    func setupNotificationActions() {
        // Pay Now action
        let payNowAction = UNNotificationAction(
            identifier: "PAY_NOW",
            title: "Pay Now",
            options: [.foreground]
        )

        // Snooze action
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Remind Me Later",
            options: []
        )

        // Payment reminder category
        let paymentCategory = UNNotificationCategory(
            identifier: "PAYMENT_REMINDER",
            actions: [payNowAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        // Overdue payment category
        let overdueCategory = UNNotificationCategory(
            identifier: "OVERDUE_PAYMENT",
            actions: [payNowAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([paymentCategory, overdueCategory])
    }

    // MARK: - Badge Management

    /// Updates app icon badge to show number of pending payments
    /// Provides at-a-glance visibility of outstanding payment obligations
    func updateBadgeCount() {
        let walletManager = WalletManager.shared
        let pendingCount = walletManager.paymentRecords.filter { $0.status == "pending" }.count

        DispatchQueue.main.async {
            UNUserNotificationCenter.current().setBadgeCount(pendingCount)
        }
    }

    /// Clears the app icon badge count to zero
    /// Used when all payments are completed or user manually clears notifications
    func clearBadge() {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().setBadgeCount(0)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Determines how notifications are displayed when app is in foreground
    /// Shows banner, sound, and badge even when app is active for better user awareness
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handles user interaction with notification actions (Pay Now, Snooze, tap)
    /// Processes action identifiers and performs corresponding operations like rescheduling or navigation
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Handle notification actions
        switch response.actionIdentifier {
        case "PAY_NOW":
            // TODO: Navigate to payment screen
            print("Pay Now tapped for payment: \(userInfo)")

        case "SNOOZE":
            // Reschedule notification for 1 hour later
            if let paymentID = userInfo["paymentRecordID"] as? String,
               let amount = userInfo["amount"] as? Double,
               let payeeName = userInfo["payeeName"] as? String {
                let content = UNMutableNotificationContent()
                content.title = "Payment Reminder"

                // Use the same format as the original reminder
                let formattedAmount = CurrencyManager.shared.format(amount: amount)
                if let restaurantName = userInfo["restaurantName"] as? String, !restaurantName.isEmpty {
                    content.body = "\(restaurantName) - \(payeeName)'s payment of \(formattedAmount) is pending"
                } else {
                    content.body = "\(payeeName)'s payment of \(formattedAmount) is pending"
                }

                content.sound = .default
                content.categoryIdentifier = "PAYMENT_REMINDER"
                content.userInfo = userInfo

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "snoozed_\(paymentID)",
                    content: content,
                    trigger: trigger
                )

                center.add(request)
            }

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            print("Notification tapped: \(userInfo)")

        default:
            break
        }

        completionHandler()
    }
}

// MARK: - Reminder Schedule

enum ReminderSchedule {
    case oneDayBefore
    case threeDaysBefore
    case oneWeekBefore
    case multipleDays // 7, 3, and 1 days before
    case custom([Int]) // Custom days before due date
}

// MARK: - Notification Preferences

struct NotificationPreferences: Codable {
    var enabled: Bool = true
    var reminderSchedule: String = "multipleDays" // Store as string for UserDefaults
    var overdueRemindersEnabled: Bool = true
    var soundEnabled: Bool = true
    var badgeEnabled: Bool = true

    /// Loads notification preferences from UserDefaults or returns default values
    /// Provides persistence of user notification settings across app sessions
    static func load() -> NotificationPreferences {
        guard let data = UserDefaults.standard.data(forKey: "notificationPreferences"),
              let preferences = try? JSONDecoder().decode(NotificationPreferences.self, from: data) else {
            return NotificationPreferences()
        }
        return preferences
    }

    /// Saves current notification preferences to UserDefaults
    /// Ensures user settings persist across app launches and device restarts
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "notificationPreferences")
        }
    }
}
