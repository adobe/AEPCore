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

// Testable implemetation for `ExtensionRuntime`, enable easy setup for the input and verification of the output of an extension
class TestableExtensionRuntime:ExtensionRuntime{
    
    var listeners:[String:EventListener] = [:]
    var dispatchedEvents: [Event] = []
    var createdSharedStates: [[String : Any]?] = []
    var mockedSharedStates: [String: (value: [String : Any]?, status: SharedStateStatus)] = [:]
    
    // MARK: ExtensionRuntime methods implemenation
    
    func registerListener(type: EventType, source: EventSource, listener: @escaping EventListener) {
        listeners["\(type)-\(source)"] = listener
    }
    
    func dispatch(event: Event) {
        dispatchedEvents += [event]
    }
    
    func createSharedState(data: [String : Any], event: Event?) {
        self.createdSharedStates += [data]
    }
    
    func createPendingSharedState(event: Event?) -> SharedStateResolver {
        return { data in
            self.createdSharedStates += [data]
        }
    }
    
    func getSharedState(extensionName: String, event: Event?) -> (value: [String : Any]?, status: SharedStateStatus)? {
        // if there is an shared state setup for the specific (extension, event id) pair, return it. Otherwise, return the shared state that is setup for the extension.
        if let id = event?.id{
            return mockedSharedStates["\(extensionName)-\(id)"] ?? mockedSharedStates["\(extensionName)"]
        }
        return mockedSharedStates["\(extensionName)"]
    }
    
    func startEvents() {
    }
    
    func stopEvents() {
    }
    
    // MARK: Helper methods
    
    /// Simulate the events that are being sent to event hub, if there is a listener registered for that type of event, that listener will receive the event
    /// - Parameters:
    ///   - events: the sequence of the events
    func simulateComingEvents(_ events:Event...){        
        for event in events {
            listeners["\(event.type)-\(event.source)"]?(event)
            listeners["\(EventType.wildcard)-\(EventSource.wildcard)"]?(event)
        }
    }
    
    /// Get the listener that is registered for the specific event source and type
    /// - Parameters:
    ///   - type: event type
    ///   - source: event source
    func getListener(type: EventType, source: EventSource) -> EventListener?{
        return listeners["\(type)-\(source)"]
    }
    
    
    /// Simulate the shared state of an extension for a matching event 
    /// - Parameters:
    ///   - pair: the (extension, event) pair
    ///   - data: the shared state tuple (value, status)
    func simulateSharedState(for pair:(extensionName: String, event: Event), data: (value: [String : Any]?, status: SharedStateStatus)){
        mockedSharedStates["\(pair.extensionName)-\(pair.event.id)"] = data
    }
    
    /// Simulate the shared state of an certain extension ignoring the event id
    /// - Parameters:
    ///   - extensionName: extension name
    ///   - data: the shared state tuple (value, status)
    func simulateSharedState(for extensionName: String, data: (value: [String : Any]?, status: SharedStateStatus)){
        mockedSharedStates["\(extensionName)"] = data
    }
    
    /// clear the events and shared states that have been created by the current extension
    func resetDispatchedEventAndCreatedSharedStates(){
        dispatchedEvents = []
        createdSharedStates = []
    }
    
    
}
