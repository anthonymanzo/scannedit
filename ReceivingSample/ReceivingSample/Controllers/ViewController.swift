import ScanditBarcodeCapture
import Foundation

class ViewController: UIViewController {
    private var whova_url: String?
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
        print("Here is the scanned data: \(barcodeData)")
        // Look for WHOVA formatted data, theirs is an email address. If found, handle accordingly
        if isValidEmail(barcodeData) {
            print("Detected WHOVA email: \(barcodeData)")
            
            // Perform API lookup for WHOVA email
            guard let lookupURL = URL(string: "http://badgeserver.local:8000/badgeprinter/whova_precheckin?email=\(barcodeData)") else { return }
            
            let task = URLSession.shared.dataTask(with: lookupURL) { data, response, error in
                guard let data = data, error == nil else {
                    print("Failed to fetch data: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let registrationId = jsonResponse["pk"] as? Int,
                       let conference = jsonResponse["conference"] as? String  {
                        let conferenceEncoded = conference.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        self.whova_url  = "http://badgeserver.local:8000/badgeprinter/checkin?conference=\(conferenceEncoded)&pk=\(registrationId)"
                        print("Whova URL: \(self.whova_url as Optional)")
                        DispatchQueue.main.async {
                            print("Registration PK: \(registrationId), Conference: \(conference)")
                            // Store or use the registrationId as needed for subsequent actions
                        }
                        
                    } else {
                        DispatchQueue.main.async {
                            print("No registration found for email: \(barcodeData)")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        print("Failed to parse JSON response: \(error.localizedDescription)")
                    }
                }
            }
            task.resume()
        }
        
        var urlString = ""
        
        if (self.whova_url ?? "").isEmpty {
            urlString = barcodeData
        }
        
        else {
            urlString = self.whova_url!
        }
        
        print("URL to be used: \(urlString)") // Debug info
        guard let url = URL(string: urlString) else { return }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            print("opening url")
            var success = false
            if let httpResponse = response as? HTTPURLResponse {
                success = (200...299).contains(httpResponse.statusCode)
            }
            
            DispatchQueue.main.async {
                if success {
                    print("GET request successful: \(url)")
                } else {
                    print("GET request failed: \(url)")
                }
            }
        }
        task.resume()
        

        DispatchQueue.main.async {
            self.tableView.viewModel?.addBarcode(barcode)
        }
    }

    private func isValidEmail(_ data: String) -> Bool {
        // Updated regex to fix invalid escape sequence
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegEx)
        return emailPredicate.evaluate(with: data)
    }
    
//    private func isValidURL(_ data: String) -> Bool {
//        let urlRegEx = "(http|https)://((\\w|-)+\\.)+(\\w|-)+(\\:\\d+)?(/.*)?"
//        let urlPredicate = NSPredicate(format: "SELF MATCHES[c] %@", urlRegEx)
//        return urlPredicate.evaluate(with: data)
//    }
}

// MARK: - SparkScanViewUIDelegate Protocol Implementation

extension ViewController: SparkScanViewUIDelegate {
    func barcodeCountButtonTapped(in view: SparkScanView) {
        performSegue(withIdentifier: "ShowBarcodeCount", sender: nil)
    }
}
