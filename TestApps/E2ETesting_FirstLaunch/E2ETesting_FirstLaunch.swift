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


import XCTest

class E2ETesting_FirstLaunch: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFirstLaunchRule() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Load AEP SDK"].tap()
        XCTAssert(app.staticTexts["Eventhub Booted"].waitForExistence(timeout: 5))
        sleep(3)
        app.buttons["Verify First Launch Rule"].tap()
        XCTAssert(app.staticTexts["Install event got evaluated"].waitForExistence(timeout: 5))
    }
}
