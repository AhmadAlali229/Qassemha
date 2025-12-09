#Introduction

Qassemha is an iOS application developed by **Ahmad Alali** and **Bader Alqahtani** as a university project with the goal of turning a simple idea into a working, real-world solution. The app is designed to make bill splitting easier and more organized by allowing users to scan receipts, select participants, and automatically calculate how much each person should pay.

This project was created for academic purposes, but it also reflects our ambition to transform everyday problems into practical digital products. Qassemha is a first step toward bringing our idea to life and exploring how it could evolve into a fully polished solution in the future.

# Qassemha

Qassemha is an iOS app that helps you **scan receipts and split bills smartly** between friends, family, or groups.  
It uses the camera to read receipts / barcodes / QR codes, lets you adjust items, and keeps track of who owes what and who paid.

> 🎯 This project is a **student / prototype app**, not a production-ready banking or payment system.

---

## Features

### 📸 Receipt Scanning & OCR

- Camera-based scanning using **AVFoundation**, **VisionKit**, and **Vision**.
- Detects:
  - Standard barcodes
  - QR codes (including encoded receipt info)
  - Printed text (OCR) to extract items and totals
- Supports:
  - Live camera preview
  - Captured image processing
  - Text extraction with a loading / processing state
- Demo receipts are available for testing without needing a real physical receipt.

---

### 🧮 Smart Bill Splitting

Located mainly under `BillSplit/` and `Models/`:

- Data models for:
  - `Receipt`, `ReceiptItem`
  - `Participant`, `SplitConfiguration`, `ItemAssignment`, etc.
- Multiple split types (`SplitType`):
  - **Equal split**  
  - **By item**  
  - **By percentage**  
  - **Custom amounts**
- Per-item assignments:
  - Each item can be assigned to one or more participants.
  - Each item can have its own split strategy (equal / custom).
- Split summary views:
  - Shows each participant’s share, totals, and status.
  - Read-only summary for sent / demo receipts.
- Split state is preserved per receipt using `BillSplitManager`.

---

### 👥 Contacts & Groups

Under `Contacts/`, `Groups/`, and Core Data model:

- **Contacts**
  - Core Data entity `Contact` plus a `ContactManager`.
  - Ability to initialize **dummy contacts** for testing.
  - Contacts can be reused across splits and groups.
- **Groups**
  - Core Data entity `SavedGroup` with members (`GroupMember`).
  - `GroupsView` and `GroupDetailView` for:
    - Viewing groups
    - Managing members
    - Using groups for faster participant selection in bill splits.

---

### 💳 Wallet & Payments

Under `WalletManager`, `Payment/`, and related views:

- **WalletManager**
  - Tracks:
    - Wallet balance
    - Pending payments
    - Total paid / received
    - History of transactions
  - Uses Core Data `Transaction` and related entities.
- **Payment Flow**
  - `PaymentFlowView` guides the user through:
    - Viewing summary of what they owe
    - Choosing payment method (wallet, etc.)
    - Adding notes
    - Confirming payment
  - Completing a payment updates wallet and bill split state.
- **Note:**  
  There is **no real payment gateway integration** (no bank or card provider).  
  All payments are simulated and stored locally for demonstration.

---

### 🧾 History & Receipt Management

Under `History/` and `Receipt/`:

- View scanned / stored receipts (`StoredReceipt`).
- Open a receipt to:
  - View detailed items
  - Open or edit its bill split configuration
  - See payment status
- Support for **demo/example receipts** with special handling (read-only, not saved).

---

### 🔐 Authentication & Session

Under `LoginFlow/` and `Services/AuthenticationManager.swift`:

- **Signup / Login / Forgot Password / Reset Password** flows.
- `AuthenticationManager`:
  - Manages current user session.
  - Integrates with Core Data `User` entity.
- ⚠️ Security note:  
  Credentials and session handling are **local-only and simplified** for a university project (not suitable as-is for production security).

---

### 🛠 Settings & Notifications

Under `Settings/` and `Services/`:

- **Settings views**:
  - Edit profile (name, email, etc.)
  - Notification settings
  - Currency switcher (via `CurrencyManager`)
- **Notifications** (`NotificationManager`):
  - Local notifications using `UserNotifications`.
  - Reminders for:
    - Pending bill splits
    - Overdue payments
  - Badge count updates.
- **Theme**
  - App currently prefers **light mode** (`preferredColorScheme(.light)`).

---

## Architecture & Project Structure

Main app folder: `Qassemha/Qassemha/`

- `Core/`
  - `QassemhaApp.swift` – App entry point
  - `Persistence.swift` – Core Data stack (`NSPersistentContainer`)
  - `CoreDataManager.swift` – Higher-level Core Data helpers
  - `NavigationCoordinator.swift` – Tab & navigation coordination
- `Main/`
  - `ContentView.swift` – Root logic for login vs main app
  - `MainTabView.swift` – Tab bar (Home, Scan, Groups, Wallet, Settings)
  - `HomeView.swift`, etc.
- `Camera/`
  - `CameraManager.swift` – Camera, barcode, QR, OCR handling
  - `CameraCaptureView.swift` – SwiftUI camera UI
- `Receipt/`
  - Receipt review and editing screens
  - Integration between scanned data and bill splitting.
- `BillSplit/`
  - `BillSplitView.swift`, `SplitSummaryView.swift`, etc.
  - `BillSplitManager.swift` – Core bill split logic
- `Contacts/`
  - `ContactManager.swift` – Contacts CRUD + dummy data
  - `ContactPickerView.swift`
- `Groups/`
  - `GroupsView.swift`, `GroupDetailView.swift`
  - Uses Core Data `SavedGroup` and `GroupMember`.
- `Wallet/` (partly under `Services/WalletManager.swift` & related views)
  - Wallet overview, transaction summaries.
- `Payment/`
  - `PaymentFlowView.swift` – guided payment process.
- `History/`
  - Views for past receipts and scans.
- `LoginFlow/`
  - `LoginView`, `SignupView`, `ForgotPasswordView`, `NewPasswordView`, etc.
- `Models/`
  - `ReceiptModels.swift` – Receipt & demo receipt data
  - `BillSplitModels.swift` – Participants, split config, item assignments...
- `Services/`
  - `AuthenticationManager.swift`
  - `ReceiptDataService.swift` – Core Data access for receipts
  - `UserValidationService.swift`, `PasswordResetService.swift`
  - `NotificationManager.swift`
  - `CurrencyManager.swift`
  - `WalletManager.swift`
- `Settings/`
  - `CurrencySwitcherView.swift`
  - `NotificationSettingsView.swift`
  - `EditProfileView.swift`
- `Qassemha.xcdatamodeld/`
  - Core Data model:
    - `User`, `Contact`, `SavedGroup`, `GroupMember`
    - `StoredReceipt`, `StoredReceiptItem`, `QRCodeReceipt`
    - `BillSplit`, `ParticipantShare` (and related entities)
    - `Wallet`, `Transaction`, etc.
- `Assets.xcassets/`
  - App icon, logo, accent colors.

---

## Tech Stack

- **Language**: Swift
- **UI Framework**: SwiftUI
- **Architecture**: MVVM-style with managers / services + Core Data models
- **Persistence**:
  - Core Data (`PersistenceController`, entities above)
  - `UserDefaults` for a few small flags and migrations
- **Frameworks**:
  - `AVFoundation`, `VisionKit`, `Vision`, `CoreImage`
  - `UserNotifications`
  - `CoreData`
  - `UIKit` (where needed, interoperating with SwiftUI)

---

## Requirements

- **Xcode**: 15 or later
- **iOS Deployment Target**: iOS 17.0+ (project also has configs referencing iOS 18.5)
- A physical device is recommended for:
  - Camera scanning
  - Realistic performance and notifications  
  (The simulator has limited camera and notification behavior.)

---

## Getting Started

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd Qassemha

2.	Open in Xcode

	Open Qassemha/Qassemha.xcodeproj in Xcode.

3.	Select a target

	Choose an iPhone simulator or a physical device with iOS 17+.

4.	Build & Run

	Press ⌘ + R in Xcode to build and run.

5.	Permissions
	
	On first launch, the app will ask for access to:

	Camera (for receipt scanning)

	Notifications (for payment reminders)

	Allow these for full functionality.
