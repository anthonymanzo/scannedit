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

import ScanditIdCapture

class SupportedSidesDataSource: DataSource {
    weak var delegate: DataSourceDelegate?

    init(delegate: DataSourceDelegate) {
        self.delegate = delegate
    }

    // MARK: - Sections

    lazy var sections: [Section] = {
        let rows: [Row] = SupportedSides.allCases.map { supportedSide in
            Row.option(title: supportedSide.description,
                       getValue: { SettingsManager.current.supportedSides == supportedSide },
                       didSelect: { _, _ in SettingsManager.current.supportedSides = supportedSide },
                       dataSourceDelegate: self.delegate)
        }

        return [
            Section(rows: rows)
        ]
    }()
}
