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

import AEPServices
import Foundation

/// An Event to be dispatched by the Event Hub
@objc(AEPEvent)
public class Event: NSObject, Codable {
    /// Name of the event
    @objc public let name: String

    /// unique identifier for the event
    @objc public private(set) var id = UUID()

    /// The `EventType` for the event
    @objc public let type: String

    /// The `EventSource` for the event
    @objc public let source: String

    /// Optional data associated with this event
    @objc public private(set) var data: [String: Any]?

    /// Date this event was created
    @objc public private(set) var timestamp = Date()

    /// If `responseID` is not nil, then this event is a response event and `responseID` is the `event.id` of the `triggerEvent`
    @objc public private(set) var responseID: UUID?

    /// Event description used for logging
    @objc override public var description: String {
        return """
            [
              id: \(id.uuidString)
              name: \(name)
              type: \(type)
              source: \(source)
              data: \(PrettyDictionary.prettify(data))
              timestamp: \(timestamp.description)
              responseId: \(String(describing: responseID?.uuidString))
              mask: \(String(describing: mask))
            ]
        """
    }

    /// Specifies the properties in the Event and its `data` that should be used in the hash for `EventHistory` storage.
    @objc public private(set) var mask: [String]?

    /// A calculated hash that represents this Event as defined by its properties and the provided `mask`
    @objc public lazy var eventHash: UInt32 = {
        return data?.fnv1a32(mask: mask) ?? 0
    }()

    /// Creates a new `Event` with the given parameters
    /// - Parameters:
    ///   - name: Name for the `Event`
    ///   - type: `EventType` for the `Event`
    ///   - source: `EventSource` for the `Event`
    ///   - data: Any associated data with this `Event`
    @objc
    public convenience init(name: String, type: String, source: String, data: [String: Any]?) {
        self.init(name: name, type: type, source: source, data: data, requestEvent: nil)
    }

    /// Creates a new `Event` with the given parameters
    /// - Parameters:
    ///   - name: Name for the `Event`
    ///   - type: `EventType` for the `Event`
    ///   - source: `EventSource` for the `Event`
    ///   - data: Any associated data with this `Event`
    ///   - mask: Defines which properties should be used in creation of the Event's hash
    @objc
    public convenience init(name: String, type: String, source: String, data: [String: Any]?, mask: [String]? = nil) {
        self.init(name: name, type: type, source: source, data: data, requestEvent: nil, mask: mask)
    }

    /// Creates a new `Event` with the given parameters
    /// - Parameters:
    ///   - name: Name for the `Event`
    ///   - type: `EventType` for the `Event`
    ///   - source: `EventSource` for the `Event`
    ///   - data: Any associated data with this `Event`
    ///   - requestEvent: The requesting `Event` for which this `Event` will be a response
    ///   - mask: Defines which properties should be used in creation of the Event's hash
    private init(name: String, type: String, source: String, data: [String: Any]?, requestEvent: Event?, mask: [String]? = nil) {
        self.name = name
        self.type = type
        self.source = source
        self.data = data
        responseID = requestEvent?.id
        self.mask = mask
    }

    /// Creates a new `Event` where the `responseID` is equal to the `id` of this `Event`
    /// - Parameters:
    ///   - name: Name for the `Event`
    ///   - type: `EventType` for the `Event`
    ///   - source: `EventSource` for the `Event`
    ///   - data: Any associated data with this `Event`
    @objc(responseEventWithName:type:source:data:)
    public func createResponseEvent(name: String, type: String, source: String, data: [String: Any]?) -> Event {
        return Event(name: name, type: type, source: source, data: data, requestEvent: self)
    }

    /// Clones the current `Event` with updated data
    /// - Parameters:
    ///   - data: Any associated data with this `Event`
    internal func copyWithNewData(data: [String: Any]?) -> Event {
        let newEvent = Event(name: self.name, type: self.type, source: self.source, data: data, mask: self.mask)
        newEvent.id = self.id
        newEvent.timestamp = self.timestamp
        newEvent.responseID = self.responseID
        return newEvent
    }
    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case name
        case id
        case type
        case source
        case data
        case timestamp
        case responseID
        case mask
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        name = try values.decode(String.self, forKey: .name)
        id = try values.decode(UUID.self, forKey: .id)
        type = try values.decode(String.self, forKey: .type)
        source = try values.decode(String.self, forKey: .source)
        let anyCodableDict = try? values.decode([String: AnyCodable].self, forKey: .data)
        data = AnyCodable.toAnyDictionary(dictionary: anyCodableDict)
        timestamp = try values.decode(Date.self, forKey: .timestamp)
        responseID = try? values.decode(UUID.self, forKey: .responseID)
        mask = try? values.decode([String].self, forKey: .mask)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(source, forKey: .source)
        try container.encode(AnyCodable.from(dictionary: data), forKey: .data)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(responseID, forKey: .responseID)
        try container.encode(mask, forKey: .mask)
    }
}
