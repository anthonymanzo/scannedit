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

extension DataCaptureContext {
    // Enter your Scandit License key here.
    // Your Scandit License key is available via your Scandit SDK web account.
    private static let licenseKey = "AujUUGdrQvgqNMrEAmUt/w02rYwJABlEoyZzRLQSpOi/fVXdvGbGnFF4iKH2Fmp9TnLAagNCRqvEK5G/UHqVdX9/5/bRZZa35mAADGFoE7VrAztr6CpYz3Md8/jyOEEN+LS8mC/KodesTZUi4dRtqmQvZI97kupUDFzbV5MgQYGPnRa/+Bf+pD/H3dbG8nWTt/30LKMQuqsRQ2PrNfYh6NjdgEGUg/JQ9wx0RUCyEk897SLSR1Jc1pPrxqvEXTvQ6ISjjTUlRJDwpPbWDlcgVlh3+ZE7JARHp3eLrWaG7q2WDbwGqZ/CYOEyx7vyF+HLFVOkEtw0uyaqW+n6ddf+0kHltdlKUQ6Nl3ZIUEQviK5zGdjB+J1ctQZkJEDzH/ckbjKXTc1CYbONQsUmZNMzqcMxRiCsKrBJO9beQALeDleaQWsoq1g6YSDl7Pt/ymbhWnQuEKBx9T6KFIeSiAP7kOq5rehFQWf27liZvy3Anm3YFHnvLWqQ/TmT/7DbQWsqnmMMgr8LW6B3WRA7iQMM9N3F0MLyzcTktW2+eTw5OY/0vBfqRAvx7IVdJG5kkQGcsy4iT34OFufC7FIcEoNwDcN9woY6B2wC9EuqB+OgxYtYjF5dQluMKhq0FuqPM0GH3i2kM9sJi5cprhZEqShjbl0E9c3ekc+hlSvUm4gTvmjsso+rRB8V3FJk069enHyhFJtPTRkTM6+0x71taInPyFltCun3j9oh2GpP3ElnP6Tz9MlH1amG+1cPGQ107aoXmwuk/XafwCtb+usLB3iYTIlzdpqLE5MuN1wwbZ0T"

    // Get a licensed DataCaptureContext
    static var licensed: DataCaptureContext {
        return DataCaptureContext(licenseKey: licenseKey)
    }
}
