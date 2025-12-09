//
//  NotificationSettingsView.swift
//  Qassemha
//
//  Settings for payment notification preferences
//

import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var preferences = NotificationPreferences.load()
    @State private var showingPermissionAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                // Permission Status
                Section {
                    HStack {
                        Image(systemName: notificationManager.notificationPermissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(notificationManager.notificationPermissionGranted ? .green : .red)

                        Text("Notifications")
                            .font(.system(size: 16, weight: .semibold))

                        Spacer()

                        Text(notificationManager.notificationPermissionGranted ? "Enabled" : "Disabled")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    if !notificationManager.notificationPermissionGranted {
                        Button(action: requestNotificationPermission) {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(.blue)

                                Text("Enable Notifications")
                                    .font(.system(size: 15, weight: .medium))
                            }
                        }
                    }
                } header: {
                    Text("Permission")
                } footer: {
                    Text("Allow Qassemha to send you reminders about pending payments.")
                }

                // Reminder Settings
                if notificationManager.notificationPermissionGranted {
                    Section {
                        Toggle("Payment Reminders", isOn: $preferences.enabled)
                            .onChange(of: preferences.enabled) { _ in
                                preferences.save()
                            }

                        if preferences.enabled {
                            Picker("Reminder Schedule", selection: $preferences.reminderSchedule) {
                                Text("1 Day Before").tag("oneDayBefore")
                                Text("3 Days Before").tag("threeDaysBefore")
                                Text("1 Week Before").tag("oneWeekBefore")
                                Text("Multiple Reminders").tag("multipleDays")
                            }
                            .onChange(of: preferences.reminderSchedule) { _ in
                                preferences.save()
                            }
                        }
                    } header: {
                        Text("Reminder Schedule")
                    } footer: {
                        if preferences.reminderSchedule == "multipleDays" {
                            Text("Reminders will be sent 7 days, 3 days, 1 day before, and on the due date.")
                        } else {
                            Text("You'll receive a reminder based on your selected schedule.")
                        }
                    }

                    Section {
                        Toggle("Overdue Payment Alerts", isOn: $preferences.overdueRemindersEnabled)
                            .onChange(of: preferences.overdueRemindersEnabled) { _ in
                                preferences.save()
                            }
                    } header: {
                        Text("Overdue Payments")
                    } footer: {
                        Text("Get notified every 3 days about overdue payments.")
                    }

                    Section {
                        Toggle("Sound", isOn: $preferences.soundEnabled)
                            .onChange(of: preferences.soundEnabled) { _ in
                                preferences.save()
                            }

                        Toggle("Badge Count", isOn: $preferences.badgeEnabled)
                            .onChange(of: preferences.badgeEnabled) { _ in
                                preferences.save()
                                if !preferences.badgeEnabled {
                                    notificationManager.clearBadge()
                                } else {
                                    notificationManager.updateBadgeCount()
                                }
                            }
                    } header: {
                        Text("Notification Style")
                    }

                    Section {
                        Button(action: testNotification) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.blue)

                                Text("Send Test Notification")
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                        }
                    } header: {
                        Text("Test")
                    }
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Enable Notifications", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("To receive payment reminders, please enable notifications in Settings.")
            }
        }
    }

    /// Requests notification permission from the user
    /// Shows alert if permission is denied
    private func requestNotificationPermission() {
        notificationManager.requestNotificationPermission { granted in
            if !granted {
                showingPermissionAlert = true
            }
        }
    }

    /// Sends a test notification to verify settings
    /// Schedules notification to appear after 2 seconds
    private func testNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Payment Reminder"
        content.body = "Restaurant Name - John's payment of $25.50 is pending"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending test notification: \(error)")
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
}
