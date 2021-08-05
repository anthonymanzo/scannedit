/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIKit
import ScanditIdCapture

class MainViewController: UIViewController {

    private enum DocumentType {
        case drivingLicense
        case passport

        var documentType: IdDocumentType {
            switch self {
            case .drivingLicense:
                return .aamvaBarcode
            case .passport:
                return .passportMRZ
            }
        }
    }

    private lazy var context = DataCaptureContext.licensed
    private lazy var camera = Camera.default
    private lazy var captureView = DataCaptureView(context: context, frame: view.bounds)

    private var idCaptureSettings = IdCaptureSettings()

    private lazy var idCapture = IdCapture(context: nil,
                                   settings: idCaptureSettings)
    private lazy var idCaptureOverlay = IdCaptureOverlay(idCapture: idCapture,
                                                 view: captureView)

    @IBOutlet private weak var scanningModeToggle: ScanningModeToggle!
    @IBOutlet private weak var passportModeButton: UIButton!
    @IBOutlet private weak var dlModeButton: UIButton!
    @IBOutlet private weak var manualScanButton: UIButton!
    @IBOutlet private weak var instructionLabel: UILabel!

    private lazy var frontSideTooltip: PopOver<UILabel> = {
        let tooltip = PopOver<UILabel>(frame: CGRect(x: 0, y: 0, width: 176, height: 106))
        tooltip.content.text = "Can't scan? Try scanning the front of card."
        tooltip.content.numberOfLines = 0
        tooltip.content.textAlignment = .center
        tooltip.content.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        tooltip.translatesAutoresizingMaskIntoConstraints = false
        return tooltip
    }()

    private var frontSideTooltipWasShown = false
    private var dlScanningMode = ScanningMode.barcode {
        didSet {
            configureUI()
            configureIdCapture()
        }
    }

    private var mode: DocumentType = .drivingLicense {
        didSet {
            configureUI()
            configureIdCapture()
        }
    }

    private var supportedDocument: IdDocumentType {
        switch mode {
        case .drivingLicense:
            switch dlScanningMode {
            case .barcode:
                return .aamvaBarcode
            case .viz:
                return .dlVIZ
            }
        case .passport:
            return .passportMRZ
        }
    }

    private var manualScanTimer: Timer?
    private var frontScanTimer: Timer?
    private var verificationDidCompleteToken: NSObjectProtocol?

    private func stopManualScanTimer() {
        manualScanTimer?.invalidate()
        manualScanTimer = nil
    }

    private func stopFrontScanTimer() {
        frontScanTimer?.invalidate()
        frontScanTimer = nil
        frontSideTooltip.isHidden = true
    }

    private func startManualScanTimer() {
        guard manualScanTimer == nil else { return }
        manualScanTimer = Timer(timeInterval: 8, repeats: false, block: { [unowned self] _ in
            self.stopManualScanTimer()
            self.manualScanButton.isHidden = false
        })
        RunLoop.main.add(manualScanTimer!, forMode: .default)
    }

    private func startFrontScanTimer() {
        guard frontScanTimer == nil else { return }
        guard mode == .drivingLicense, dlScanningMode == .barcode else { return }
        guard !frontSideTooltipWasShown else {
            self.frontSideTooltip.isHidden = false
            return
        }

        frontScanTimer = Timer(timeInterval: 4, repeats: false, block: { [unowned self] _ in
            self.stopFrontScanTimer()
            self.frontSideTooltipWasShown = true
            self.frontSideTooltip.isHidden = false
        })
        RunLoop.main.add(frontScanTimer!, forMode: .default)
    }

    private func configureIdCapture() {
        idCapture.removeListener(self)
        captureView.removeOverlay(idCaptureOverlay)
        context.removeAllModes()

        let settings = idCaptureSettings
        settings.supportedDocuments = supportedDocument
        idCapture = IdCapture(context: context, settings: settings)
        idCapture.isEnabled = true
        idCapture.addListener(self)
        idCaptureOverlay = IdCaptureOverlay(idCapture: idCapture,
                                            view: captureView)
        idCaptureOverlay.setIdLayout(.auto)
    }

    private func configureUI() {
        dlModeButton.isSelected = mode == .drivingLicense
        passportModeButton.isSelected = mode == .passport

        switch mode {
        case .passport:
            stopFrontScanTimer()
            instructionLabel.text = "Align Character Strip"
        case .drivingLicense:
            switch dlScanningMode {
            case .barcode:
                instructionLabel.text = "Align Back of Card"
            case .viz:
                instructionLabel.text = "Align Front of Card"
            }
        }

        let selectedFont = UIFont.boldSystemFont(ofSize: 16)
        let normalFont = UIFont.systemFont(ofSize: 16)
        dlModeButton.titleLabel?.font = dlModeButton.isSelected ? selectedFont : normalFont
        passportModeButton.titleLabel?.font = passportModeButton.isSelected ? selectedFont : normalFont

        scanningModeToggle.isHidden = mode == .passport
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.addSubview(captureView)
        view.sendSubviewToBack(captureView)
        captureView.translatesAutoresizingMaskIntoConstraints = false
        captureView
            .topAnchor
            .constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            .isActive = true
        captureView
            .leadingAnchor
            .constraint(equalTo: view.leadingAnchor)
            .isActive = true
        captureView
            .trailingAnchor
            .constraint(equalTo: view.trailingAnchor)
            .isActive = true
        captureView
            .bottomAnchor
            .constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            .isActive = true

        view.addSubview(frontSideTooltip)
        frontSideTooltip
            .centerXAnchor
            .constraint(equalTo: view.centerXAnchor)
            .isActive = true
        frontSideTooltip
            .topAnchor
            .constraint(equalTo: scanningModeToggle.bottomAnchor,
                        constant: 16)
            .isActive = true
        frontSideTooltip
            .widthAnchor
            .constraint(equalToConstant: 176)
            .isActive = true
        frontSideTooltip
            .heightAnchor
            .constraint(equalToConstant: 96)
            .isActive = true

        scanningModeToggle.delegate = self
        context.setFrameSource(camera, completionHandler: nil)

        configureUI()

        verificationDidCompleteToken =
            NotificationCenter
            .default
            .addObserver(forName: .deliveryResultDidComplete,
                         object: nil,
                         queue: .main) { _ in
                self.reset()
            }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        camera?.switch(toDesiredState: .on)
        reset()
    }

    private func reset() {
        frontSideTooltipWasShown = false
        manualScanButton.isHidden = true
        frontSideTooltip.isHidden = true
        scanningModeToggle.reset()
        mode = .drivingLicense
        dlScanningMode = .barcode

        startScanning()
    }

    private func startScanning() {
        // Reset the timers
        stopFrontScanTimer()
        stopManualScanTimer()

        startFrontScanTimer()

        // Start scanning
        configureIdCapture()
    }

    @IBAction private func modeButtonAction(_ sender: UIButton) {
        mode = sender == dlModeButton ? .drivingLicense : .passport
        stopManualScanTimer()
        startManualScanTimer()
    }

    @IBAction private func manualScanAction(_ sender: Any) {
        let identifier = "ManualDocumentInputTableTableViewController"
        guard
            let manualDocumentInputVC = storyboard?
                .instantiateViewController(identifier: identifier)
                as? ManualDocumentInputTableTableViewController else { return }
        let transitionManager = TransitionManager()
        let navigationController = CompactNavigationController(rootViewController: manualDocumentInputVC)
        navigationController.transitioningDelegate = transitionManager
        navigationController.modalPresentationStyle = .overCurrentContext
        navigationController.transitionManager = transitionManager
        present(navigationController, animated: true, completion: nil)
    }

    private func showResultViewController(capturedId: CapturedId) {
        guard
            let deliveryResultViewController = storyboard?
                .instantiateViewController(identifier: "DeliveryResultViewController")
                as? DeliveryResultViewController else { return }
        let transitionManager = TransitionManager()
        deliveryResultViewController.transitioningDelegate = transitionManager
        deliveryResultViewController.modalPresentationStyle = .overCurrentContext
        deliveryResultViewController.transitionManager = transitionManager
        deliveryResultViewController.configure(capturedId: capturedId)
        present(deliveryResultViewController, animated: true, completion: nil)
    }
}

extension MainViewController: DocumentTypeToggleListener {
    func toggleDidChange(newState: ScanningMode) {
        dlScanningMode = newState
        stopFrontScanTimer()

        switch dlScanningMode {
        case .barcode:
            startFrontScanTimer()
        case .viz:
            startManualScanTimer()
        }
    }
}

extension MainViewController: IdCaptureListener {
    func idCapture(_ idCapture: IdCapture,
                   didCaptureIn session: IdCaptureSession,
                   frameData: FrameData) {
        guard let capturedId = session.newlyCapturedId else { return }
        idCapture.isEnabled = false
        DispatchQueue.main.async {
            self.stopFrontScanTimer()
            self.stopManualScanTimer()
            self.showResultViewController(capturedId: capturedId)
        }
    }
}
