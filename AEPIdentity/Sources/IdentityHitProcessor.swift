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

class IdentityHitProcessor: HitProcessing {
    private let LOG_TAG = "IdentityHitProcessor"

    let retryInterval = TimeInterval(30)
    private let responseHandler: (IdentityHit, Data?) -> Void
    private var isEdgeRegistered: () -> Bool
    private var edgeRegistered = false
    private var networkService: Networking {
        return ServiceProvider.shared.networkService
    }

    /// Creates a new `IdentityHitProcessor` where the `responseHandler` will be invoked after each successful processing of a hit
    /// - Parameter responseHandler: a function to be invoked with the `DataEntity` for a hit and the response data for that hit
    /// - Parameter isEdgeRegistered: a closure which resolves if the edge extension is registered or not
    init(responseHandler: @escaping (IdentityHit, Data?) -> Void, isEdgeRegistered: @escaping () -> Bool) {
        self.responseHandler = responseHandler
        self.isEdgeRegistered = isEdgeRegistered
    }

    // MARK: HitProcessing

    func processHit(entity: DataEntity, completion: @escaping (Bool) -> Void) {
        guard let data = entity.data, let identityHit = try? JSONDecoder().decode(IdentityHit.self, from: data) else {
            // failed to convert data to hit, unrecoverable error, move to next hit
            completion(true)
            return
        }

        let headers = [NetworkServiceConstants.Headers.CONTENT_TYPE: NetworkServiceConstants.HeaderValues.CONTENT_TYPE_URL_ENCODED]
        let networkRequest = NetworkRequest(url: identityHit.url, httpMethod: .get, connectPayload: "", httpHeaders: headers, connectTimeout: IdentityConstants.Default.TIMEOUT, readTimeout: IdentityConstants.Default.TIMEOUT)

        networkService.connectAsync(networkRequest: networkRequest) { connection in
            self.handleNetworkResponse(hit: identityHit, connection: connection, completion: completion)
        }
    }

    func shouldQueue(entity: DataEntity) -> Bool {
        if edgeRegistered { return false } // minor optimization to reduce calls to getSharedState

        // only queue hits if Edge is not registered
        edgeRegistered = isEdgeRegistered()
        if !edgeRegistered {
            Log.debug(label: "\(LOG_TAG):shouldQueue", "AEP Edge is enabled, sending identifiers in XDM format to the Edge extension.")
        }
        return !edgeRegistered
    }

    // MARK: Helpers

    /// Handles the network response after a hit has been sent to the server
    /// - Parameters:
    ///   - hit: the `IdentityHit`
    ///   - connection: the connection returned after we make the network request
    ///   - completion: a completion block to invoke after we have handled the network response with true for success and false for failure (retry)
    private func handleNetworkResponse(hit: IdentityHit, connection: HttpConnection, completion: @escaping (Bool) -> Void) {
        if connection.responseCode == 200 {
            // hit sent successfully
            Log.debug(label: "\(LOG_TAG):\(#function)", "Identity hit request with url \(hit.url.absoluteString) sent successfully")
            responseHandler(hit, connection.data)
            completion(true)
        } else if NetworkServiceConstants.RECOVERABLE_ERROR_CODES.contains(connection.responseCode ?? -1) {
            // retry this hit later
            Log.warning(label: "\(LOG_TAG):\(#function)", "Retrying Identity hit, request with url \(hit.url.absoluteString) failed with error \(connection.error?.localizedDescription ?? "") and recoverable status code \(connection.responseCode ?? -1)")
            completion(false)
        } else {
            // unrecoverable error. delete the hit from the database and continue
            Log.warning(label: "\(LOG_TAG):\(#function)", "Dropping Identity hit, request with url \(hit.url.absoluteString) failed with error \(connection.error?.localizedDescription ?? "") and unrecoverable status code \(connection.responseCode ?? -1)")
            responseHandler(hit, connection.data)
            completion(true)
        }
    }
}
