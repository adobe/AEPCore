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
import AEPCore

/// Represents the JSON structure for the company context
private struct CompanyContext: Codable {
    let namespace = "imsOrgID"
    let marketingCloudId: String
}

/// Represents the JSON structure for a list of `UserID`
private struct Users: Codable {
    let userIDs: [UserID]
}

/// Represents a user id with a namespace, value, and type
private struct UserID: Codable {
    let namespace: String
    let value: String
    let type: String
}

/// Responsible for reading the shared state of multiple extensions to read the identifiers
struct MobileIdentities: Codable {

    typealias SharedStateProvider = (String, Event?) -> SharedStateResult?
    private var companyContexts: [CompanyContext]?
    private var users: [Users]?

    static let NAMESPACE_MCID = "4"
    static let INTEGRATION_CODE = "integrationCode"
    static let NAMESPACE_ID = "namespaceId"
    static let MCPNS_DPID = "20920"
    static let IDFA_DSID = "DSID_20915"

    /// Collects all the identities from various extensions and packages them into a JSON string
    /// - Parameters:
    ///   - event: the `Event` generated by the GetSdkIdentities API
    ///   - sharedStateProvider: a function that can resolve `SharedState` given an extension name
    /// - Returns: a JSON formatted string with all the identities from various extensions
    mutating func collectIdentifiers(event: Event, sharedStateProvider: SharedStateProvider) {
        if let companyContexts = getCompanyContexts(event: event, sharedStateProvider: sharedStateProvider) {
            self.companyContexts = [companyContexts]
        }

        var userIds = [UserID]()
        userIds.append(contentsOf: getVisitorIdentifiers(event: event, sharedStateProvider: sharedStateProvider))
        // TODO: Analytics
        // TODO: Audience
        // TODO: Target

        if !userIds.isEmpty {
            self.users = [Users(userIDs: userIds)]
        }
    }

    /// Determines if all the shared states required to collect identities are ready
    /// - Parameters:
    ///   - event: the `Event` generated by the GetSdkIdentities API
    ///   - sharedStateProvider: a function that can resolve `SharedState` given an extension name
    /// - Returns: True if all shared states are ready, false otherwise
    func areSharedStatesReady(event: Event, sharedStateProvider: SharedStateProvider) -> Bool {
        let identityStatus = sharedStateProvider(IdentityConstants.EXTENSION_NAME, event)?.status ?? .none
        let configurationStatus = sharedStateProvider(IdentityConstants.EXTENSION_NAME, event)?.status ?? .none
        // TODO: Analytics
        // TODO: Audience
        // TODO: Target
        return identityStatus != .pending && configurationStatus != .pending
    }

    // MARK: Private APIs

    /// Gets all the required identity from the Identity extension
    /// - Parameters:
    ///   - event: the `Event` generated by the GetSdkIdentities API
    ///   - sharedStateProvider: a function that can resolve `SharedState` given an extension name
    /// - Returns: a list of all the Identity extension identities in the form of a `UserID`
    private func getVisitorIdentifiers(event: Event, sharedStateProvider: SharedStateProvider) -> [UserID] {
        guard let identitySharedState = sharedStateProvider(IdentityConstants.EXTENSION_NAME, event) else { return [] }
        guard identitySharedState.status == .set else { return [] }

        var visitorIds = [UserID]()

        // marketing cloud id
        if let marketingCloudId = identitySharedState.value?[IdentityConstants.EventDataKeys.VISITOR_ID_MID] as? String {
            visitorIds.append(UserID(namespace: MobileIdentities.NAMESPACE_MCID, value: marketingCloudId, type: MobileIdentities.NAMESPACE_ID))
        }

        // visitor ids and advertising id
        // Identity sets the advertising identifier both in ‘visitoridslist’ and as ‘advertisingidentifer’ in the Identity shared state.
        // So, there is no need to fetch the advertising identifier with advertisingidentifer namespace DSID_20914 separately.
        if let customVisitorIds = identitySharedState.value?[IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] as? [CustomIdentity] {
            // convert each `CustomIdentity` to a `UserID`, then remove any nil values
            visitorIds.append(contentsOf: customVisitorIds.map {$0.toUserID()}.compactMap {$0})
        }

        // push identifier
        if let pushId = identitySharedState.value?[IdentityConstants.EventDataKeys.PUSH_IDENTIFIER] as? String, !pushId.isEmpty {
            visitorIds.append(UserID(namespace: MobileIdentities.MCPNS_DPID, value: pushId, type: MobileIdentities.INTEGRATION_CODE))
        }

        return visitorIds
    }

    /// Gets all the required identity from the Configuration extension
    /// - Parameters:
    ///   - event: the `Event` generated by the GetSdkIdentities API
    ///   - sharedStateProvider: a function that can resolve `SharedState` given an extension name
    /// - Returns: a list of all the Configuration extension identities in the form of a `CompanyContext`
    private func getCompanyContexts(event: Event, sharedStateProvider: SharedStateProvider) -> CompanyContext? {
        guard let configurationSharedState = sharedStateProvider(IdentityConstants.SharedStateKeys.CONFIGURATION, event) else { return nil }
        guard configurationSharedState.status == .set else { return nil }
        guard let marketingCloudOrgId = configurationSharedState.value?[IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String, !marketingCloudOrgId.isEmpty else { return nil }

        return CompanyContext(marketingCloudId: marketingCloudOrgId)
    }
}

private extension CustomIdentity {

    /// Converts a `CustomIdentity` into a `UserID`
    /// - Returns: a `UserID` where the namespace is value, value is identifier, and type is integrationCode
    func toUserID() -> UserID? {
        guard let type = type, let identifier = identifier, !identifier.isEmpty else { return nil }
        return UserID(namespace: type, value: identifier, type: MobileIdentities.INTEGRATION_CODE)
    }
}
