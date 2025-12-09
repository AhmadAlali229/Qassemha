//
//  ScanReceiptView.swift
//  Qassemha
//
//  Created by Harjot Singh on 21/09/25.
//

import SwiftUI
import AVFoundation

struct ScanReceiptView: View {
    @StateObject private var demoData = DemoReceiptData.shared
    @State private var isAnimating = false
    @State private var showingCamera = false
    @State private var showingManualEntry = false
    @State private var showingReceiptReview = false
    @State private var capturedReceipt: Receipt?
    @State private var recentReceipts: [Receipt] = []
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var showingCameraPermissionAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                Spacer()

                // Main Scan Section
                VStack(spacing: 24) {
                    // Animated Camera Icon
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 100, height: 100)
                            .scaleEffect(isAnimating ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.blue)
                            .scaleEffect(isAnimating ? 1.02 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    }

                    VStack(spacing: 12) {
                        Text("Scan Your Receipt")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        Text("Point your camera at a receipt to automatically extract items and prices")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }

                // Action Buttons
                VStack(spacing: 16) {
                    // Scan Receipt Button
                    Button(action: {
                        if cameraPermissionStatus == .authorized {
                            showingCamera = true
                        } else {
                            requestCameraPermission()
                        }
                    }) {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 20, weight: .semibold))

                            Text("Start Scanning")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .cyan]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }

                    // Manual Entry Button
                    Button(action: {
                        showingManualEntry = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 18, weight: .medium))

                            Text("Add Items Manually")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.blue, lineWidth: 2)
                        )
                    }

                }
                .padding(.horizontal, 30)

                Spacer()

                // Recent Scans Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Recent Scans")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)

                        Spacer()

                        Button("View All") {
                            // View all action - could navigate to history tab
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    }

                    if recentReceipts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)

                            Text("No recent scans")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)

                            Text("Your scanned receipts will appear here")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(recentReceipts.prefix(3)) { receipt in
                                RecentScanCard(receipt: receipt) {
                                    capturedReceipt = receipt
                                    showingReceiptReview = true
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 20)
                }
            }
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
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                isAnimating = true
                loadRecentReceipts()
                requestCameraPermission()
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraCaptureView(isPresented: $showingCamera, capturedReceipt: $capturedReceipt)
        }
        .sheet(isPresented: $showingManualEntry) {
            NavigationView {
                VStack {
                    Text("Manual Item Entry")
                        .font(.title)
                        .padding()

                    Spacer()

                    Text("Manual item entry functionality will be implemented here")
                        .foregroundColor(.secondary)
                        .padding()

                    Spacer()
                }
                .navigationTitle("Add Items")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingManualEntry = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingReceiptReview) {
            if let receipt = capturedReceipt {
                ReceiptReviewView(
                    receipt: .constant(receipt),
                    isPresented: $showingReceiptReview
                )
            }
        }
        .onChange(of: capturedReceipt) { newReceipt in
            if let newReceipt = newReceipt {
                recentReceipts.insert(newReceipt, at: 0)
                if recentReceipts.count > 10 {
                    recentReceipts = Array(recentReceipts.prefix(10))
                }
                showingReceiptReview = true
            }
        }
        .alert("Camera Permission Required", isPresented: $showingCameraPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Camera access is required to scan receipts. Please enable camera permission in Settings.")
        }
    }

    private func loadRecentReceipts() {
        // In a real app, this would load from Core Data or UserDefaults
        // For demo purposes, we'll start with some sample data after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if recentReceipts.isEmpty {
                recentReceipts = Array(demoData.sampleReceipts.prefix(2))
            }
        }
    }

    private func requestCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch cameraPermissionStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionStatus = granted ? .authorized : .denied
                    if !granted {
                        self.showingCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            // Camera access denied or restricted
            print("Camera access denied")
            showingCameraPermissionAlert = true
        case .authorized:
            // Camera access already granted
            print("Camera access authorized")
        @unknown default:
            break
        }
    }
}

struct RecentScanCard: View {
    let receipt: Receipt
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Category Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(receipt.category.color.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: receipt.category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(receipt.category.color)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(receipt.storeName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack {
                        Text("\(receipt.items.count) items")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Image(systemName: receipt.scanType.icon)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Text(receipt.scanType.description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Text(receipt.formattedDate)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Total Amount and Arrow
                HStack(spacing: 8) {
                    Text(receipt.formattedTotal)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ScanReceiptView()
}