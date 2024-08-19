import ScanditBarcodeCapture
import Foundation

class ViewController: UIViewController {
    @IBOutlet private weak var tableView: ItemsTableView!
    @IBOutlet private weak var clearListButton: UIButton!

    private var itemsTableViewModel: ItemsTableViewModel!
    private let context = DataCaptureContext.licensed

    private lazy var sparkScan: SparkScan = {
        let settings = SparkScanSettings()
        Set<Symbology>([.ean13UPCA, .ean8, .upce, .code39, .code128, .qr]).forEach {
            settings.set(symbology: $0, enabled: true)
        }

        let mode = SparkScan(settings: settings)
        return mode
    }()

    private var sparkScanView: SparkScanView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "QR & Badge Scanning"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationController?.navigationBar.tintColor = .white
        setupRecognition()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sparkScanView.prepareScanning()
        tableView.viewModel = itemsTableViewModel
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sparkScanView.stopScanning()
    }

    @IBAction private func didPressClearListButton(_ sender: UIButton) {
        tableView.viewModel?.clear()
    }
}

// MARK: - Update View Methods

extension ViewController {

    private func setupRecognition() {
        sparkScan.addListener(self)
    }

    private func setupUI() {
        sparkScanView = SparkScanView(parentView: view,
                                      context: context,
                                      sparkScan: sparkScan,
                                      settings: SparkScanViewSettings())
        sparkScanView.isBarcodeCountButtonVisible = true
        sparkScanView.uiDelegate = self
        itemsTableViewModel = ItemsTableViewModel()
        tableView.allowEditing = true
        clearListButton.styleAsSecondaryButton()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let barcodeCountVC = segue.destination as? BarcodeCountViewController {
            sparkScan.isEnabled = false
            barcodeCountVC.context = context
            barcodeCountVC.itemsTableViewModel = itemsTableViewModel
        }
    }
}

// MARK: - SparkScanListener Protocol Implementation

extension ViewController: SparkScanListener {

    func sparkScan(_ sparkScan: SparkScan, didScanIn session: SparkScanSession, frameData: FrameData?) {
        guard let barcode = session.newlyRecognizedBarcode, let barcodeData = barcode.data else {
            return
        }
        // Look for WHOVA formatted data, theirs is an email address.  If found,
        
        // Then format into a url with what's available(hopefully) or an api call.
        
        // Check if the scanned data is a valid URL
        if let url = URL(string: barcodeData), UIApplication.shared.canOpenURL(url) {
            // Trigger the GET request in the background
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                var success = false
                if let httpResponse = response as? HTTPURLResponse {
                    success = (200...299).contains(httpResponse.statusCode)
                }
                
                // Here you can add logic to handle the success or failure of the request
                // For example, updating the UI or logging the result
                DispatchQueue.main.async {
                    if success {
                        // Handle successful response
                        print("GET request successful: \(url)")
                    } else {
                        // Handle failed response
                        print("GET request failed: \(url)")
                    }
                }
            }
            task.resume()  // Start the background task
        }

        DispatchQueue.main.async {
            self.tableView.viewModel?.addBarcode(barcode)
        }
    }
}

// MARK: - SparkScanViewUIDelegate Protocol Implementation

extension ViewController: SparkScanViewUIDelegate {
    func barcodeCountButtonTapped(in view: SparkScanView) {
        performSegue(withIdentifier: "ShowBarcodeCount", sender: nil)
    }
}
