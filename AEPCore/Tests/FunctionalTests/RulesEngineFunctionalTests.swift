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

@testable import AEPCore
import AEPCoreMocks
import AEPServices
import AEPServicesMocks
import XCTest

/// Functional tests for the rules engine feature
class RulesEngineFunctionalTests: XCTestCase {
    var mockSystemInfoService: MockSystemInfoService!
    var mockRuntime: TestableExtensionRuntime!
    var rulesEngine: LaunchRulesEngine!

    override func setUp() {
        UserDefaults.clear()
        mockRuntime = TestableExtensionRuntime()
        rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: mockRuntime)
        rulesEngine.trace { _, _, _, failure in
            print(failure)
        }
    }

    static var rulesUrl: URL? {
        return Bundle(for: self).url(forResource: "rules_functional_1", withExtension: ".zip")
    }

    func testUpdateConfigurationWithDictTwice() {
        // setup
        let event = Event(name: "Configure with file path", type: EventType.lifecycle, source: EventSource.responseContent,
                          data: ["lifecyclecontextdata": ["launchevent": "LaunchEvent"]])

        let filePath = Bundle(for: RulesEngineFunctionalTests.self).url(forResource: "rules_functional_1", withExtension: ".zip")
        let expectedData = try? Data(contentsOf: filePath!)

        let httpResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let mockNetworkService = TestableNetworkService()
        mockNetworkService.mockRespsonse = (data: expectedData, respsonse: httpResponse, error: nil)
        ServiceProvider.shared.networkService = mockNetworkService
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T"]], status: .set))

        // test
        rulesEngine.loadRemoteRules(from: "http://test.com/rules.url")
        let processedEvent = rulesEngine.process(event: event)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual("value", processedEvent.data?["key"] as? String)
    }

    func testReprocessEvents() {
        // setup
        let event = Event(name: "Configure with file path", type: EventType.lifecycle, source: EventSource.responseContent,
                          data: ["lifecyclecontextdata": ["launchevent": "LaunchEvent"]])

        let filePath = Bundle(for: RulesEngineFunctionalTests.self).url(forResource: "rules_functional_1", withExtension: ".zip")
        let expectedData = try? Data(contentsOf: filePath!)

        let httpResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let mockNetworkService = TestableNetworkService()
        mockNetworkService.mockRespsonse = (data: expectedData, respsonse: httpResponse, error: nil)
        ServiceProvider.shared.networkService = mockNetworkService
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T"]], status: .set))
        // test
        _ = rulesEngine.process(event: event)

        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // test
        rulesEngine.loadRemoteRules(from: "http://test.com/rules.url")
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        // test
        _ = rulesEngine.process(event: mockRuntime.dispatchedEvents[0])
        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let secondEvent = mockRuntime.dispatchedEvents[1]
        XCTAssertEqual("Rules Consequence Event", secondEvent.name)
        XCTAssertEqual(EventType.rulesEngine, secondEvent.type)
        XCTAssertEqual(EventSource.responseContent, secondEvent.source)
    }

    // Group: OR & AND
    func testGroupLogicalOperators() {
        // setup
        resetRulesEngine(withNewRules: "rules_testGroupLogicalOperators")
        let event = Event(name: "Configure with file path", type: EventType.lifecycle, source: EventSource.responseContent,
                          data: ["lifecyclecontextdata": ["launchevent": "LaunchEvent"]])

        // test
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // test
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T"]], status: .set))
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: eq
    func testMatcherEq() {
        // covered by `RulesEngineFunctionalTests.testGroupLogicalOperators()`
    }

    // Matcher: ne
    func testMatcherNe() {
        // setup
        resetRulesEngine(withNewRules: "rules_testMatcherNe")
        let event = Event(name: "Configure with file path", type: EventType.lifecycle, source: EventSource.responseContent,
                          data: ["lifecyclecontextdata": ["launchevent": "LaunchEvent"]])
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T"]], status: .set))
        // test
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // test
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "Verizon"]], status: .set))
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: ex
    func testMatcherEx() {
        // covered by `RulesEngineFunctionalTests.testGroupLogicalOperators()`
    }

    // Matcher: nx (Not Exists)
    func testMatcherNx() {
        // setup
        resetRulesEngine(withNewRules: "rules_testMatcherNx")
        let event = Event(name: "Configure with file path", type: EventType.lifecycle, source: EventSource.responseContent,
                          data: ["lifecyclecontextdata": ["launchevent": "LaunchEvent"]])
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T"]], status: .set))
        // test
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // test
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: nil, status: .pending))
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: gt (Greater Than)
    func testMatcherGt() {
        // setup
        resetRulesEngine(withNewRules: "rules_testMatcherGt")
        let event = Event(name: "Configure with file path", type: EventType.lifecycle, source: EventSource.responseContent,
                          data: ["lifecyclecontextdata": ["launchevent": "LaunchEvent"]])
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 2]], status: .set))
        // test
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // test
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 3]], status: .set))
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: ge (Greater Than or Equals)
    func testMatcherGe() {
        // setup
        resetRulesEngine(withNewRules: "rules_testMatcherGe")
        let event = Event(name: "Configure with file path", type: EventType.lifecycle, source: EventSource.responseContent,
                          data: ["lifecyclecontextdata": ["launchevent": "LaunchEvent"]])
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 1]], status: .set))
        // test
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // test
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 2]], status: .set))
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: lt (Less Than)
    func testMatcherLt() {
        // setup
        resetRulesEngine(withNewRules: "rules_testMatcherLt")
        let event = Event(name: "Configure with file path", type: EventType.lifecycle, source: EventSource.responseContent,
                          data: ["lifecyclecontextdata": ["launchevent": "LaunchEvent"]])
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 2]], status: .set))
        // test
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // test
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 1]], status: .set))
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: le (Less Than or Equals)
    func testMatcherLe() {
        // setup
        resetRulesEngine(withNewRules: "rules_testMatcherLe")
        let event = Event(name: "Configure with file path", type: EventType.lifecycle, source: EventSource.responseContent,
                          data: ["lifecyclecontextdata": ["launchevent": "LaunchEvent"]])
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 3]], status: .set))
        // test
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // test
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 2]], status: .set))
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: co (Contains)
    func testMatcherCo() {
        // setup
        resetRulesEngine(withNewRules: "rules_testMatcherCo")
        let event = Event(name: "Configure with file path", type: EventType.lifecycle, source: EventSource.responseContent,
                          data: ["lifecyclecontextdata": ["launchevent": "LaunchEvent"]])
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "Verizon"]], status: .set))
        // test
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // test
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&"]], status: .set))
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: nc (Not Contains)
    func testMatcherNc() {
        // setup
        resetRulesEngine(withNewRules: "rules_testMatcherNc")
        let event = Event(name: "Configure with file path", type: EventType.lifecycle, source: EventSource.responseContent,
                          data: ["lifecyclecontextdata": ["launchevent": "LaunchEvent"]])
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&"]], status: .set))
        // test
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // test
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "Verizon"]], status: .set))
        _ = rulesEngine.process(event: event)
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    private func resetRulesEngine(withNewRules rulesJsonFileName: String) {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: rulesJsonFileName, withExtension: "json"), let data = try? Data(contentsOf: url) else {
            XCTFail()
            return
        }
        guard let rules = JSONRulesParser.parse(data) else {
            XCTFail()
            return
        }
        rulesEngine.rulesEngine.clearRules()
        rulesEngine.rulesEngine.addRules(rules: rules)
    }
}
