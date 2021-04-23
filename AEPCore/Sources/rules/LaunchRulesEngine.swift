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
import AEPRulesEngine

/// A rules engine for Launch rules
public class LaunchRulesEngine {
    private let LOG_TAG = RulesConstants.LOG_MODULE_PREFIX
    private static let LAUNCH_RULE_TOKEN_LEFT_DELIMITER = "{%"
    private static let LAUNCH_RULE_TOKEN_RIGHT_DELIMITER = "%}"
    private static let CONSEQUENCE_EVENT_NAME = "Rules Consequence Event"
    private static let CONSEQUENCE_EVENT_DATA_KEY_ID = "id"
    private static let CONSEQUENCE_EVENT_DATA_KEY_TYPE = "type"
    private static let CONSEQUENCE_EVENT_DATA_KEY_DETAIL = "detail"
    private static let CONSEQUENCE_EVENT_DATA_KEY_CONSEQUENCE = "triggeredconsequence"
    private static let CONSEQUENCE_TYPE_ADD = "add"
    private static let CONSEQUENCE_TYPE_MOD = "mod"

    private let transform: Transforming
    private let name: String
    private let extensionRuntime: ExtensionRuntime
    private let rulesQueue: DispatchQueue
    private var waitingEvents: [Event]?
    private let dataStore: NamedCollectionDataStore

    let evaluator: ConditionEvaluator
    let rulesEngine: RulesEngine<LaunchRule>

    /// Creates a new rules engine instance
    /// - Parameters:
    ///   - name: the unique name for the current instance
    ///   - extensionRuntime: the `extensionRuntime`
    public init(name: String, extensionRuntime: ExtensionRuntime) {
        self.name = name
        rulesQueue = DispatchQueue(label: "com.adobe.rulesengine.\(name)")
        transform = LaunchRuleTransformer.createTransforming()
        dataStore = NamedCollectionDataStore(name: "\(RulesConstants.DATA_STORE_PREFIX).\(self.name)")
        evaluator = ConditionEvaluator(options: .caseInsensitive)
        rulesEngine = RulesEngine(evaluator: evaluator, transformer: transform)
        waitingEvents = [Event]()
        // you can enable the log when debugging rules engine
//        if RulesEngineLog.logging == nil {
//            RulesEngineLog.logging = RulesEngineNativeLogging()
//        }
        self.extensionRuntime = extensionRuntime
    }

    /// Register a `RulesTracer`
    /// - Parameter tracer: a `RulesTracer` closure to know result of rules evaluation
    func trace(with tracer: @escaping RulesTracer) {
        rulesEngine.trace(with: tracer)
    }

    /// Set a new set of rules, the new rules replace the current rules. A RulesEngine Reset event will be dispatched to trigger the reprocess for the waiting events.
    /// - Parameter rules: the array of new `LaunchRule`
    public func replaceRules(with rules: [LaunchRule]) {
        rulesQueue.async {
            self.rulesEngine.clearRules()
            self.rulesEngine.addRules(rules: rules)
            Log.debug(label: self.LOG_TAG, "Successfully loaded \(rules.count) rule(s) into the (\(self.name)) rules engine.")
        }
        self.sendReprocessEventsRequest()
    }

    /// Evaluates all the current rules against the supplied `Event`.
    /// - Parameters:
    ///   - event: the `Event` against which to evaluate the rules
    ///   - sharedStates: the `SharedState`s registered to the `EventHub`
    /// - Returns: the  processed`Event`
    public func process(event: Event) -> Event {
        rulesQueue.sync {
            // if our waitingEvents array is nil, we know we have rules registered and can skip to evaluation
            guard let currentWaitingEvents = waitingEvents else {
                return evaluateRules(for: event)
            }

            // check if this is an event to kick processing of waitingEvents
            // otherwise, add the event to waitingEvents
            if (event.data?[RulesConstants.Keys.RULES_ENGINE_NAME] as? String) == name, event.source == EventSource.requestReset, event.type == EventType.rulesEngine {
                for currentEvent in currentWaitingEvents {
                    _ = evaluateRules(for: currentEvent)
                }
                waitingEvents = nil
            } else {
                waitingEvents?.append(event)
            }
            return evaluateRules(for: event)
        }
    }

    private func evaluateRules(for event: Event) -> Event {
        let traversableTokenFinder = TokenFinder(event: event, extensionRuntime: extensionRuntime)
        var matchedRules: [LaunchRule]?
        matchedRules = rulesEngine.evaluate(data: traversableTokenFinder)
        guard let matchedRulesUnwrapped = matchedRules else {
            return event
        }
        var eventData = event.data
        for rule in matchedRulesUnwrapped {
            for consequence in rule.consequences {
                let consequenceWithConcreteValue = replaceToken(for: consequence, data: traversableTokenFinder)
                switch consequenceWithConcreteValue.type {
                case LaunchRulesEngine.CONSEQUENCE_TYPE_ADD:
                    guard let from = consequenceWithConcreteValue.eventData else {
                        Log.error(label: LOG_TAG, "(\(self.name)) : Unable to process an AttachDataConsequence Event, 'eventData' is missing from 'details'")
                        continue
                    }
                    guard let to = eventData else {
                        Log.error(label: LOG_TAG, "(\(self.name)) : Unable to process an AttachDataConsequence Event, 'eventData' is missing from original event")
                        continue
                    }
                    Log.trace(label: LOG_TAG, "(\(self.name)) : Attaching event data with \(PrettyDictionary.prettify(from))\n")
                    eventData = EventDataMerger.merging(to: to, from: from, overwrite: false)
                case LaunchRulesEngine.CONSEQUENCE_TYPE_MOD:
                    guard let from = consequenceWithConcreteValue.eventData else {
                        Log.error(label: LOG_TAG, "(\(self.name)) : Unable to process a ModifyDataConsequence Event, 'eventData' is missing from 'details'")
                        continue
                    }
                    guard let to = eventData else {
                        Log.error(label: LOG_TAG, "(\(self.name)) : Unable to process a ModifyDataConsequence Event, 'eventData' is missing from original event")
                        continue
                    }
                    Log.trace(label: LOG_TAG, "(\(self.name)) : Modifying event data with \(PrettyDictionary.prettify(from))\n")
                    eventData = EventDataMerger.merging(to: to, from: from, overwrite: true)
                default:
                    if let event = generateConsequenceEvent(consequence: consequenceWithConcreteValue) {
                        Log.trace(label: LOG_TAG, "(\(self.name)) : Generating new consequence event \(event)")
                        extensionRuntime.dispatch(event: event)
                    }
                }
            }
        }
        event.data = eventData
        return event
    }

    /// Replace tokens inside the provided consequence with the right value
    /// - Parameters:
    ///   - consequence: the `Consequence` instance may contain tokens
    ///   - data: a `Traversable` collection with tokens and related values
    /// - Returns: a new instance of `Consequence`
    internal func replaceToken(for consequence: RuleConsequence, data: Traversable) -> RuleConsequence {
        let dict = replaceToken(in: consequence.details, data: data)
        return RuleConsequence(id: consequence.id, type: consequence.type, details: dict)
    }

    private func replaceToken(in dict: [String: Any?], data: Traversable) -> [String: Any?] {
        var mutableDict = dict
        for (key, value) in mutableDict {
            switch value {
            case is String:
                mutableDict[key] = replaceToken(for: value as! String, data: data)
            case is [String: Any]:
                let valueDict = mutableDict[key] as! [String: Any]
                mutableDict[key] = replaceToken(in: valueDict, data: data)
            default:
                break
            }
        }
        return mutableDict
    }

    private func replaceToken(for value: String, data: Traversable) -> String {
        let template = Template(templateString: value, tagDelimiterPair: (LaunchRulesEngine.LAUNCH_RULE_TOKEN_LEFT_DELIMITER, LaunchRulesEngine.LAUNCH_RULE_TOKEN_RIGHT_DELIMITER))
        return template.render(data: data, transformers: transform)
    }

    private func sendReprocessEventsRequest() {
        extensionRuntime.dispatch(event: Event(name: name, type: EventType.rulesEngine, source: EventSource.requestReset, data: [RulesConstants.Keys.RULES_ENGINE_NAME: name]))
    }

    /// Generate a consequence event with provided consequence data
    /// - Parameter consequence: a consequence of the rule
    /// - Returns: a consequence `Event`
    private func generateConsequenceEvent(consequence: RuleConsequence) -> Event? {
        var dict: [String: Any] = [:]
        dict[LaunchRulesEngine.CONSEQUENCE_EVENT_DATA_KEY_DETAIL] = consequence.details
        dict[LaunchRulesEngine.CONSEQUENCE_EVENT_DATA_KEY_ID] = consequence.id
        dict[LaunchRulesEngine.CONSEQUENCE_EVENT_DATA_KEY_TYPE] = consequence.type
        return Event(name: LaunchRulesEngine.CONSEQUENCE_EVENT_NAME, type: EventType.rulesEngine, source: EventSource.responseContent, data: [LaunchRulesEngine.CONSEQUENCE_EVENT_DATA_KEY_CONSEQUENCE: dict])
    }
}
