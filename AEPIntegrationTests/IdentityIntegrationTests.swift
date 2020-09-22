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
@testable import AEPCore
@testable import AEPServices
import AEPIdentity
import AEPLifecycle
import AEPSignal

class IdentityIntegrationTests: XCTestCase {

    override func setUp() {
        UserDefaults.clear()
        FileManager.default.clearCache()
        ServiceProvider.shared.reset()
        EventHub.reset()
    }

    override func tearDown() {

        let initExpectation = XCTestExpectation(description: "init extensions")
        MobileCore.unregisterExtension(Identity.self) {
            initExpectation.fulfill()
        }
        wait(for: [initExpectation], timeout: 2)
    }

    func initExtensionsAndWait() {
        let initExpectation = XCTestExpectation(description: "init extensions")
        MobileCore.setLogLevel(level: .trace)
        MobileCore.registerExtensions([Identity.self, Lifecycle.self, Signal.self]) {
            initExpectation.fulfill()
        }
        wait(for: [initExpectation], timeout: 0.5)
    }

    func testSyncIdentifiers() {
        initExtensionsAndWait()

        let requestExpectation = XCTestExpectation(description: "syncIdentifiers request")
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.mock { request in
            if request.url.absoluteString.contains("d_cid_ic=id1%2501value1%25010") {
                XCTAssertTrue(request.url.absoluteString.contains("https://test.com/id"))
                XCTAssertTrue(request.url.absoluteString.contains("d_orgid=orgid"))
                requestExpectation.fulfill()
            }
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.syncIdentifiers(identifiers: ["id1": "value1"])

        wait(for: [requestExpectation], timeout: 1)
    }

    func testOptedout() {
        initExtensionsAndWait()

        let requestExpectation = XCTestExpectation(description: "expect no syncIdentifiers request")
        requestExpectation.isInverted = true
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.mock { request in
            if request.url.absoluteString.contains("d_cid_ic=id1%2501value1%25010") {
                requestExpectation.fulfill()
            }
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedout"])
        Identity.syncIdentifiers(identifiers: ["id1": "value1"])

        wait(for: [requestExpectation], timeout: 1)
    }

    func testGetUrlVariables() {
        initExtensionsAndWait()

        let variablesExpectation = XCTestExpectation(description: "getUrlVariables callback")

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.getUrlVariables { variables, _ in
            XCTAssertTrue(variables?.contains("TS") ?? false)
            XCTAssertTrue(variables?.contains("MCMID") ?? false)
            XCTAssertTrue(variables?.contains("MCORGID") ?? false)
            variablesExpectation.fulfill()
        }

        wait(for: [variablesExpectation], timeout: 1)
    }

    func testAppendTo() {
        initExtensionsAndWait()

        let urlExpectation = XCTestExpectation(description: "appendTo callback")
        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.appendTo(url: URL(string: "https://adobe.com")) { (url, _) in

            XCTAssertTrue(url?.absoluteString.contains("TS") ?? false)
            XCTAssertTrue(url?.absoluteString.contains("MCMID") ?? false)
            XCTAssertTrue(url?.absoluteString.contains("MCORGID") ?? false)
            urlExpectation.fulfill()
        }

        wait(for: [urlExpectation], timeout: 1)
    }

    func testGetExperienceCloudId() {
        initExtensionsAndWait()

        let urlExpectation = XCTestExpectation(description: "getExperienceCloudId callback")
        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.getExperienceCloudId { ecid in
            XCTAssertFalse(ecid!.isEmpty)
            urlExpectation.fulfill()
        }
        wait(for: [urlExpectation], timeout: 1)
    }

    func testGetSdkIdentities() {
        initExtensionsAndWait()

        let urlExpectation = XCTestExpectation(description: "getSdkIdentities callback")
        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        MobileCore.setAdvertisingIdentifier(adId: "adid")
        Identity.syncIdentifiers(identifiers: ["id1": "value1"])
        MobileCore.getSdkIdentities { identityString, _ in
            XCTAssertTrue(identityString?.contains("DSID_20915") ?? false)
            XCTAssertTrue(identityString?.contains("id1") ?? false)
            XCTAssertTrue(identityString?.contains("imsOrgID") ?? false)
            urlExpectation.fulfill()
        }
        wait(for: [urlExpectation], timeout: 2)
    }

    func testSetPushIdentifier() {
        initExtensionsAndWait()

        let requestExpectation = XCTestExpectation(description: "push identifier sync request")
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.mock { request in
            if request.url.absoluteString.contains("20920") {
                XCTAssertTrue(request.url.absoluteString.contains("d_cid=20920%25013935313632353862363233306166646439336366306364303762386464383435"))
                requestExpectation.fulfill()
            }
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        MobileCore.setPushIdentifier(deviceToken: "9516258b6230afdd93cf0cd07b8dd845".data(using: .utf8))

        wait(for: [requestExpectation], timeout: 1)
    }

    func testSetAdvertisingIdentifier() {
        initExtensionsAndWait()

        let requestExpectation = XCTestExpectation(description: "advertising identifier sync request")
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.mock { request in
            if request.url.absoluteString.contains("20915") {
                XCTAssertTrue(request.url.absoluteString.contains("d_cid_ic=DSID_20915%2501adid%25011"))
                requestExpectation.fulfill()
            }
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        MobileCore.setAdvertisingIdentifier(adId: "adid")
        wait(for: [requestExpectation], timeout: 1)
    }

}
