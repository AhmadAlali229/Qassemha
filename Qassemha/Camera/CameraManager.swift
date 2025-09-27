//
//  CameraManager.swift
//  Qassemha
//
//  Created by Harjot Singh on 21/09/25.
//

import Foundation
import AVFoundation
import UIKit
import VisionKit
import Vision
import CoreImage

class CameraManager: NSObject, ObservableObject {
    @Published var isCameraAuthorized = false
    @Published var isCameraUnavailable = false
    @Published var capturedImage: UIImage?
    @Published var detectedBarcodes: [String] = []
    @Published var isFlashOn = false
    @Published var extractedText = ""
    @Published var isProcessing = false
    @Published var error: CameraError?

    var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private var currentDevice: AVCaptureDevice?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    enum CameraError: LocalizedError {
        case unauthorized
        case configurationFailed
        case unknown(Error)

        var errorDescription: String? {
            switch self {
            case .unauthorized:
                return "Camera access is required to scan receipts"
            case .configurationFailed:
                return "Failed to configure camera"
            case .unknown(let error):
                return error.localizedDescription
            }
        }
    }

    override init() {
        super.init()
        checkCameraAuthorization()
    }

    func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
        case .notDetermined:
            requestCameraPermission()
        case .denied, .restricted:
            isCameraAuthorized = false
        @unknown default:
            isCameraAuthorized = false
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.isCameraAuthorized = granted
                if !granted {
                    self?.error = .unauthorized
                }
            }
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            self?.setupCaptureSession()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    private func setupCaptureSession() {
        guard isCameraAuthorized else {
            DispatchQueue.main.async { [weak self] in
                self?.error = .unauthorized
            }
            return
        }

        let session = AVCaptureSession()
        session.beginConfiguration()

        // Configure session preset
        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }

        // Add camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let cameraInput = try? AVCaptureDeviceInput(device: camera) else {
            DispatchQueue.main.async { [weak self] in
                self?.error = .configurationFailed
                self?.isCameraUnavailable = true
            }
            session.commitConfiguration()
            return
        }

        if session.canAddInput(cameraInput) {
            session.addInput(cameraInput)
            currentDevice = camera
        }

        // Add photo output
        let photoOutput = AVCapturePhotoOutput()
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            self.photoOutput = photoOutput
        }

        // Add video output for barcode scanning
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            self.videoOutput = videoOutput
        }

        session.commitConfiguration()
        self.captureSession = session

        DispatchQueue.main.async { [weak self] in
            self?.isCameraUnavailable = false
        }

        session.startRunning()
    }

    func capturePhoto() {
        guard let photoOutput = photoOutput else { return }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off

        DispatchQueue.main.async { [weak self] in
            self?.isProcessing = true
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func toggleFlash() {
        guard let device = currentDevice, device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                isFlashOn = false
            } else {
                try device.setTorchModeOn(level: 1.0)
                isFlashOn = true
            }
            device.unlockForConfiguration()
        } catch {
            print("Flash toggle error: \(error)")
        }
    }

    func processImage(_ image: UIImage) {
        print("📷 Starting image processing...")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.performTextRecognition(on: image)
            self?.performBarcodeDetection(on: image)
        }
    }

    private func performTextRecognition(on image: UIImage) {
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async { [weak self] in
                self?.isProcessing = false
                self?.error = .configurationFailed
            }
            return
        }

        // Preprocess image for better text recognition
        let preprocessedImage = preprocessImageForOCR(cgImage)

        let request = VNRecognizeTextRequest { [weak self] request, error in
            if let error = error {
                print("Text recognition error: \(error)")
                DispatchQueue.main.async {
                    self?.isProcessing = false
                    self?.error = .unknown(error)
                }
                return
            }

            let observations = request.results as? [VNRecognizedTextObservation] ?? []

            // Get multiple candidates for better accuracy
            var allRecognizedText: [String] = []

            for observation in observations {
                let candidates = observation.topCandidates(3)
                for candidate in candidates {
                    // Higher confidence threshold for better receipt parsing
                    if candidate.confidence > 0.3 {
                        // Clean up common OCR artifacts
                        let cleanedText = self?.cleanOCRText(candidate.string) ?? candidate.string
                        if !cleanedText.isEmpty {
                            allRecognizedText.append(cleanedText)
                            break // Take the first good candidate
                        }
                    }
                }
            }

            // Sort by reading order (top to bottom, left to right)
            let sortedObservations = observations.sorted { first, second in
                let firstBounds = first.boundingBox
                let secondBounds = second.boundingBox

                // Sort by y-coordinate first (top to bottom, note: Vision coordinates are flipped)
                if abs(firstBounds.midY - secondBounds.midY) > 0.05 {
                    return firstBounds.midY > secondBounds.midY
                }
                // If on same line, sort by x-coordinate (left to right)
                return firstBounds.midX < secondBounds.midX
            }

            let recognizedText = sortedObservations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")

            DispatchQueue.main.async {
                self?.extractedText = recognizedText
                self?.isProcessing = false

                // Print extracted text to console
                print("=== EXTRACTED TEXT FROM RECEIPT ===")
                print(recognizedText)
                print("=== END EXTRACTED TEXT ===")
            }
        }

        // Enhanced settings for receipt text recognition
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false // Disable for better number/price recognition
        request.automaticallyDetectsLanguage = true

        // Receipt-specific customizations
        if #available(iOS 16.0, *) {
            request.revision = VNRecognizeTextRequestRevision3
        }

        // Optimize for receipt text (numbers, prices, short text)
        if #available(iOS 13.0, *) {
            request.recognitionLanguages = ["en-US"] // Optimize for English receipts
        }

        // Improve confidence threshold for receipt scanning
        request.minimumTextHeight = 0.03 // Allow smaller text typical on receipts

        let handler = VNImageRequestHandler(cgImage: preprocessedImage, options: [
            VNImageOption.cameraIntrinsics: NSNull(),
            VNImageOption.properties: NSNull()
        ])

        do {
            try handler.perform([request])
        } catch {
            print("Text recognition handler error: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.isProcessing = false
                self?.error = .unknown(error)
            }
        }
    }

    private func preprocessImageForOCR(_ cgImage: CGImage) -> CGImage {
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)

        // Apply filters to enhance text readability
        var processedImage = ciImage

        // 1. Convert to grayscale for better text detection
        if let grayscaleFilter = CIFilter(name: "CIColorControls") {
            grayscaleFilter.setValue(processedImage, forKey: kCIInputImageKey)
            grayscaleFilter.setValue(0.0, forKey: kCIInputSaturationKey) // Remove color
            if let output = grayscaleFilter.outputImage {
                processedImage = output
            }
        }

        // 2. Enhance contrast and brightness (optimized for receipts)
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(processedImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(1.4, forKey: kCIInputContrastKey) // Higher contrast for receipts
            contrastFilter.setValue(0.2, forKey: kCIInputBrightnessKey) // Brighten for faded receipts
            if let output = contrastFilter.outputImage {
                processedImage = output
            }
        }

        // 3. Sharpen the image (stronger for receipt text)
        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(processedImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.6, forKey: kCIInputSharpnessKey) // Stronger sharpening
            if let output = sharpenFilter.outputImage {
                processedImage = output
            }
        }

        // Convert back to CGImage
        if let outputCGImage = context.createCGImage(processedImage, from: processedImage.extent) {
            return outputCGImage
        }

        // Return original if processing fails
        return cgImage
    }

    private func performBarcodeDetection(on image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let request = VNDetectBarcodesRequest { [weak self] request, error in
            if let error = error {
                print("Barcode detection error: \(error)")
                return
            }

            let observations = request.results as? [VNBarcodeObservation] ?? []
            let barcodes = observations.compactMap { $0.payloadStringValue }

            DispatchQueue.main.async {
                self?.detectedBarcodes = barcodes
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }

    func clearResults() {
        capturedImage = nil
        extractedText = ""
        detectedBarcodes = []
        isProcessing = false
        error = nil
    }

    private func cleanOCRText(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove common OCR artifacts
        cleaned = cleaned.replacingOccurrences(of: "§", with: "S") // Common S misrecognition
        cleaned = cleaned.replacingOccurrences(of: "©", with: "O") // Common O misrecognition
        cleaned = cleaned.replacingOccurrences(of: "®", with: "R") // Common R misrecognition
        cleaned = cleaned.replacingOccurrences(of: "™", with: "T") // Common T misrecognition

        // Fix common price formatting issues
        cleaned = cleaned.replacingOccurrences(of: "§", with: "$") // Dollar sign misrecognition
        cleaned = cleaned.replacingOccurrences(of: "＄", with: "$") // Full-width dollar sign
        cleaned = cleaned.replacingOccurrences(of: "s", with: "$", options: .regularExpression, range: cleaned.range(of: "^s\\d+\\.\\d{2}$"))

        // Remove obvious garbage (too short, too long, or all symbols)
        if cleaned.count < 1 || cleaned.count > 100 {
            return ""
        }

        // Remove lines that are just symbols or single characters
        if cleaned.count == 1 && !cleaned.isAlphanumeric {
            return ""
        }

        return cleaned
    }
}

// MARK: - String Extension

extension String {
    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async { [weak self] in
                self?.isProcessing = false
                self?.error = .configurationFailed
            }
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = image
            self?.processImage(image)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Real-time barcode detection
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard let observations = request.results as? [VNBarcodeObservation],
                  !observations.isEmpty else { return }

            let barcodes = observations.compactMap { $0.payloadStringValue }

            DispatchQueue.main.async {
                if !barcodes.isEmpty && self?.detectedBarcodes != barcodes {
                    self?.detectedBarcodes = barcodes
                }
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}

// MARK: - Camera Preview

import SwiftUI

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewView {
        return CameraPreviewView(session: session)
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        // Update handled in the UIView subclass
    }
}

class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    override var layer: AVCaptureVideoPreviewLayer {
        return super.layer as! AVCaptureVideoPreviewLayer
    }

    init(session: AVCaptureSession) {
        super.init(frame: .zero)
        layer.session = session
        layer.videoGravity = .resizeAspectFill
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}