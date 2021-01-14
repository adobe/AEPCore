/*
 Copyright 2020 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
@testable import AEPServices
import XCTest
import UIKit

class AlertMessageTests : XCTestCase {
    static let mockTitle = "mockTitle"
    static let mockMessage = "mockMessage"
    static let mockPositiveLabel = "mockPositiveLabel"
    static let mockNegativeLabel = "mockNegativeLabel"
    var alertMessage : AlertMessage?
    static var expectation: XCTestExpectation?
    var rootViewController: UIViewController!

    override func setUp() {
        alertMessage = AlertMessage(title: AlertMessageTests.mockTitle, message: AlertMessageTests.mockMessage, positiveButtonLabel: AlertMessageTests.mockPositiveLabel, negativeButtonLabel: AlertMessageTests.mockNegativeLabel, listener: MockListener())
    }

    func test_init_whenListenerIsNil() {
        alertMessage = AlertMessage(title: AlertMessageTests.mockTitle, message: AlertMessageTests.mockMessage, positiveButtonLabel: AlertMessageTests.mockPositiveLabel, negativeButtonLabel: AlertMessageTests.mockNegativeLabel, listener: nil)
        XCTAssertNotNil(alertMessage)
    }

    func test_init_whenListenerIsPresent() {
        XCTAssertNotNil(alertMessage)
    }

    class MockListener: AlertMessaging {
        func onPositiveResponse(message: AlertMessage?) {}
        func onNegativeResponse(message: AlertMessage?) {}
        func onShow(message: AlertMessage?) {}
        func onDismiss(message: AlertMessage?) {}
    }
}
