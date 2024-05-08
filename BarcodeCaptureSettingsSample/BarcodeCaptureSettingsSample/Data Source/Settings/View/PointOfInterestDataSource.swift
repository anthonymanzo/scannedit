//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied
// See the License for the specific language governing permissions and
// limitations under the License.
//

import ScanditCaptureCore

class PointOfInterestDataSource: DataSource {
    weak var delegate: DataSourceDelegate?

    init(delegate: DataSourceDelegate) {
        self.delegate = delegate
    }

    // MARK: - Sections

    lazy var sections: [Section] = {
        return [Section(rows: [
            Row.valueWithUnit(title: "X",
                              getValue: { SettingsManager.current.pointOfInterest.x },
                              didChangeValue: { SettingsManager.current.pointOfInterest.x = $0 },
                              dataSourceDelegate: self.delegate),

            Row.valueWithUnit(title: "Y",
                              getValue: { SettingsManager.current.pointOfInterest.y },
                              didChangeValue: { SettingsManager.current.pointOfInterest.y = $0 },
                              dataSourceDelegate: self.delegate)])]
    }()
}
