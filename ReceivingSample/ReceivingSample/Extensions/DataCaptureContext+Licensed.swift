import ScanditCaptureCore
import Foundation

extension DataCaptureContext {
    private static let licenseKey: String = {
        if let key = Bundle.main.object(forInfoDictionaryKey: "ScanditLicenseKey") as? String {
            return key
        }
        return ""
    }()

    static var licensed: DataCaptureContext {
        return DataCaptureContext(licenseKey: licenseKey)
    }
}
