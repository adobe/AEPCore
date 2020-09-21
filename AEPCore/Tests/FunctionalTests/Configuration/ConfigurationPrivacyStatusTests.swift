////
////  ConfigurationPrivacyStatusTests.swift
////  AEPCoreTests
////
////  Created by Christopher Hoffman on 9/17/20.
////  Copyright © 2020 Adobe. All rights reserved.
////
//
//@testable import AEPCore
//import XCTest
//import AEPCoreMocks
//import AEPServices
//import AEPServicesMocks
//import XCTest
//
//class ConfigurationPrivacyStatusTests: XCTestCase {
//    var mockRuntime: TestableExtensionRuntime!
//    var configuration: Configuration!
//    
//    override func setUp() {
//        UserDefaults.clear()
//        mockRuntime = TestableExtensionRuntime()
//        configuration = Configuration(runtime: mockRuntime)
//        configuration.onRegistered()
//        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
//    }
//
//    // MARK: getPrivacyStatus(...) tests
//    
//    /// Ensures that get response event even when config is empty
//    func testGetPrivacyStatusWhenConfigureIsEmpty() {
//        // setup
//        let event = createGetPrivacyStatusEvent()
//        
//        // test
//        mockRuntime.simulateComingEvents(event)
//        
//        // verify
//        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
//        XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
//        XCTAssertEqual(EventSource.responseContent, mockRuntime.firstEvent?.source)
//        XCTAssertEqual(0, mockRuntime.firstEvent?.data?.count)
//        XCTAssertEqual(event.id, mockRuntime.firstEvent?.responseID)
//    }
//    
//    /// Happy path for get privacy status
//    func testGetPrivacyStatusSimpleOptIn() {
//        // setup
//        let configUpdateEvent = ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["global.privacy": "optedOut"])
//        let getPrivacyStatusEvent = createGetPrivacyStatusEvent()
//        
//        // test
//        mockRuntime.simulateComingEvents(configUpdateEvent)
//        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
//        mockRuntime.simulateComingEvents(getPrivacyStatusEvent)
//        
//        // verify
//        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
//        XCTAssertEqual(1, mockRuntime.firstEvent?.data?.count)
//        XCTAssertEqual("optedOut", mockRuntime.firstEvent?.data?["global.privacy"] as? String)
//        XCTAssertEqual(getPrivacyStatusEvent.id, mockRuntime.firstEvent?.responseID)
//    }
//    
//    /// Tests that the privacy status is stored in persistance
//    func testPrivacyStatusIsStoredInPersistance() {
//        // setup
//        let configUpdateEvent = ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["global.privacy": "optedIn"])
//        let getPrivacyStatusEvent = createGetPrivacyStatusEvent()
//        
//        // test
//        mockRuntime.simulateComingEvents(configUpdateEvent)
//        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
//        mockRuntime.simulateComingEvents(getPrivacyStatusEvent)
//        
//        // verify
//        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
//        XCTAssertEqual(1, mockRuntime.firstEvent?.data?.count)
//        XCTAssertEqual("optedIn", mockRuntime.firstEvent?.data?["global.privacy"] as? String)
//        XCTAssertEqual(getPrivacyStatusEvent.id, mockRuntime.firstEvent?.responseID)
//        
//        // reboot
//        mockRuntime = TestableExtensionRuntime()
//        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
//        configuration = Configuration(runtime: mockRuntime)
//        configuration.onRegistered()
//        
//        let getPrivacyStatusEvent2 = createGetPrivacyStatusEvent()
//        mockRuntime.simulateComingEvents(getPrivacyStatusEvent2)
//        
//        XCTAssertEqual("optedIn", mockRuntime.firstEvent?.data?["global.privacy"] as? String)
//    }
//    
//    /// Tests that the privacy status being set programmatically takes priority over non programmatic configuration
//    func testSetPrivacyStatusIsTakenOverNonProgrammaticConfigChanges() {
//        let path = Bundle(for: type(of: self)).path(forResource: "ADBMobileConfig", ofType: "json")!
//        let filePathEvent = ConfigurationFileInPathTests.createConfigFilePathEvent(filePath: path)
//        // Set to optedOut because optedIn is the setting in the config file
//        let configUpdateEvent = ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["global.privacy": "optedOut"])
//        let getPrivacyStatusEvent = createGetPrivacyStatusEvent()
//        
//        // test
//        mockRuntime.simulateComingEvents(filePathEvent, configUpdateEvent)
//        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
//        mockRuntime.simulateComingEvents(getPrivacyStatusEvent)
//        // verify
//        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
//        XCTAssertEqual(16, mockRuntime.firstEvent?.data?.count)
//        XCTAssertEqual("optedOut", mockRuntime.firstEvent?.data?["global.privacy"] as? String)
//        XCTAssertEqual(getPrivacyStatusEvent.id, mockRuntime.firstEvent?.responseID)
//    }
//    
//    func createGetPrivacyStatusEvent() -> Event {
//        return Event(name: "Privacy Status Request", type: EventType.configuration, source: EventSource.requestContent, data: ["config.getData": true])
//    }
//}
