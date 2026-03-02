//
//  CameraManager.swift
//  Qassemha
//
//  OCR-only camera manager for receipt scanning.
//

import Foundation
import AVFoundation
import UIKit
import Vision
import CoreImage
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    @Published var isCameraAuthorized = false
    @Published var isCameraUnavailable = false
    @Published var capturedImage: UIImage?
    @Published var isFlashOn = false
    @Published var extractedText = ""
    @Published var isProcessing = false
    @Published var error: CameraError?
    @Published var isSessionReady = false

    var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var currentDevice: AVCaptureDevice?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue", qos: .userInitiated)
    private var isSessionConfigured = false

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
            guard let self = self else { return }

            if self.isSessionConfigured, let session = self.captureSession {
                if !session.isRunning {
                    session.startRunning()
                }
                DispatchQueue.main.async {
                    self.isSessionReady = true
                }
            } else {
                self.setupCaptureSession()
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionReady = false
            }
        }
    }

    func prepareSession() {
        guard !isSessionConfigured else { return }
        sessionQueue.async { [weak self] in
            self?.setupCaptureSession()
        }
    }

    private func setupCaptureSession() {
        guard isCameraAuthorized else {
            DispatchQueue.main.async { [weak self] in
                self?.error = .unauthorized
            }
            return
        }

        let session: AVCaptureSession
        if let existingSession = self.captureSession {
            session = existingSession
        } else {
            session = AVCaptureSession()
            self.captureSession = session
        }

        session.beginConfiguration()
        if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }

        if !isSessionConfigured {
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

            let photoOutput = AVCapturePhotoOutput()
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                self.photoOutput = photoOutput
            }

            isSessionConfigured = true
        }

        session.commitConfiguration()

        DispatchQueue.main.async { [weak self] in
            self?.isCameraUnavailable = false
            self?.isSessionReady = true
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
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.performTextRecognition(on: image)
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

        let preprocessedImage = preprocessImageForOCR(cgImage)

        let request = VNRecognizeTextRequest { [weak self] request, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isProcessing = false
                    self?.error = .unknown(error)
                }
                return
            }

            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let sortedObservations = observations.sorted { first, second in
                let firstBounds = first.boundingBox
                let secondBounds = second.boundingBox

                if abs(firstBounds.midY - secondBounds.midY) > 0.05 {
                    return firstBounds.midY > secondBounds.midY
                }
                return firstBounds.midX < secondBounds.midX
            }

            let recognizedText = sortedObservations.compactMap { observation in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                let cleaned = self?.cleanOCRText(candidate.string) ?? candidate.string
                return cleaned.isEmpty ? nil : cleaned
            }.joined(separator: "\n")

            DispatchQueue.main.async {
                self?.extractedText = recognizedText
                self?.isProcessing = false
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.automaticallyDetectsLanguage = true
        request.minimumTextHeight = 0.03

        if #available(iOS 16.0, *) {
            request.revision = VNRecognizeTextRequestRevision3
        }
        if #available(iOS 13.0, *) {
            request.recognitionLanguages = ["en-US"]
        }

        let handler = VNImageRequestHandler(cgImage: preprocessedImage, options: [
            VNImageOption.cameraIntrinsics: NSNull(),
            VNImageOption.properties: NSNull()
        ])

        do {
            try handler.perform([request])
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.isProcessing = false
                self?.error = .unknown(error)
            }
        }
    }

    private func preprocessImageForOCR(_ cgImage: CGImage) -> CGImage {
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)

        var processedImage = ciImage

        if let grayscaleFilter = CIFilter(name: "CIColorControls") {
            grayscaleFilter.setValue(processedImage, forKey: kCIInputImageKey)
            grayscaleFilter.setValue(0.0, forKey: kCIInputSaturationKey)
            if let output = grayscaleFilter.outputImage {
                processedImage = output
            }
        }

        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(processedImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(1.4, forKey: kCIInputContrastKey)
            contrastFilter.setValue(0.2, forKey: kCIInputBrightnessKey)
            if let output = contrastFilter.outputImage {
                processedImage = output
            }
        }

        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(processedImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.6, forKey: kCIInputSharpnessKey)
            if let output = sharpenFilter.outputImage {
                processedImage = output
            }
        }

        if let outputCGImage = context.createCGImage(processedImage, from: processedImage.extent) {
            return outputCGImage
        }

        return cgImage
    }

    func clearResults() {
        capturedImage = nil
        extractedText = ""
        isProcessing = false
        error = nil
    }

    private func cleanOCRText(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        cleaned = cleaned.replacingOccurrences(of: "آ§", with: "$")
        cleaned = cleaned.replacingOccurrences(of: "ï¼„", with: "$")

        if cleaned.count < 1 || cleaned.count > 100 {
            return ""
        }
        return cleaned
    }
}

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

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewView {
        CameraPreviewView(session: session)
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}
}

class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    override var layer: AVCaptureVideoPreviewLayer {
        super.layer as! AVCaptureVideoPreviewLayer
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
