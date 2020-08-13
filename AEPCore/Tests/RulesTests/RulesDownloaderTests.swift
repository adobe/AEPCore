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

@testable import AEPCore
@testable import AEPServices
@testable import AEPServicesMocks
import XCTest

class RulesDownloaderTests: XCTestCase {
    private static let zipTestFileName = "testRulesDownloader"
    private let cache = MockDiskCache()
    private var mockUnzipper = MockUnzipper()
    var rulesDownloader: RulesDownloader {
        return RulesDownloader(fileUnzipper: mockUnzipper)
    }

    // The number of items in the rules.json for verifying in tests
    private let numOfRuleDictionaryItems = 23

    static var bundle: Bundle {
        return Bundle(for: self)
    }

    static var rulesUrl: URL? {
        return RulesDownloaderTests.bundle.url(forResource: RulesDownloaderTests.zipTestFileName, withExtension: ".zip")
    }

    private var encodedUrl: String {
        let rulesUrl = RulesDownloaderTests.rulesUrl!.absoluteString
        let utf8RulesUrl = rulesUrl.data(using: .utf8)
        return utf8RulesUrl!.base64EncodedString()
    }

    override func setUp() {
        ServiceProvider.shared.cacheService = cache
    }

    func testLoadRulesFromCacheSimple() {
        let rulesData = "testdata".data(using: .utf8)!
        let testRules: CachedRules = CachedRules(cacheable: rulesData, lastModified: nil, eTag: nil)
        let dataToCache = try! JSONEncoder().encode(testRules)
        let testEntry = CacheEntry(data: dataToCache, expiry: .never, metadata: nil)
        cache.mockCache[RulesDownloaderConstants.Keys.RULES_CACHE_PREFIX + encodedUrl] = testEntry
        guard let cachedRulesData = rulesDownloader.loadRulesFromCache(rulesUrl: RulesDownloaderTests.rulesUrl!) else {
            XCTFail("Rules not loaded from cache")
            return
        }
        XCTAssertEqual(rulesData, cachedRulesData)
        XCTAssertTrue(cache.getCalled)
    }

    func testLoadRulesFromCacheNotInCache() {
        XCTAssertNil(rulesDownloader.loadRulesFromCache(rulesUrl: RulesDownloaderTests.rulesUrl!))
        XCTAssertTrue(cache.getCalled)
    }

    func testLoadRulesFromUrlWithCacheNotModified() {
        ServiceProvider.shared.networkService = MockRulesDownloaderNetworkService(response: .notModified)
        let rulesData = "testdata".data(using: .utf8)!
        let testRules: CachedRules = CachedRules(cacheable: rulesData, lastModified: nil, eTag: nil)
        let data = try! JSONEncoder().encode(testRules)
        let testEntry = CacheEntry(data: data, expiry: .never, metadata: nil)
        cache.mockCache[RulesDownloaderConstants.Keys.RULES_CACHE_PREFIX + encodedUrl] = testEntry
        let expectation = XCTestExpectation(description: "RulesDownloader invokes callback with cached rules")
        var loadedRulesData: Data?

        rulesDownloader.loadRulesFromUrl(rulesUrl: RulesDownloaderTests.rulesUrl!, completion: { loadedRules in
            loadedRulesData = loadedRules
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 0.5)
        XCTAssertNil(loadedRulesData)
        XCTAssertFalse(mockUnzipper.unzipCalled)
        XCTAssertTrue(cache.getCalled)
        XCTAssertFalse(cache.setCalled)
    }

    func testLoadRulesFromUrlWithError() {
        ServiceProvider.shared.networkService = MockRulesDownloaderNetworkService(response: .error)
        let expectation = XCTestExpectation(description: "RulesDownloader invoked callback with nil")
        rulesDownloader.loadRulesFromUrl(rulesUrl: RulesDownloaderTests.rulesUrl!, completion: { loadedRules in
            XCTAssertNil(loadedRules)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 0.5)
        XCTAssertFalse(mockUnzipper.unzipCalled)
        XCTAssertTrue(cache.getCalled)
        XCTAssertFalse(cache.setCalled)
    }

    func testLoadRulesFromUrlUnzipFail() {
        ServiceProvider.shared.networkService = MockRulesDownloaderNetworkService(response: .success)
        let expectation = XCTestExpectation(description: "RulesDownloader invoked callback with nil")
        rulesDownloader.loadRulesFromUrl(rulesUrl: RulesDownloaderTests.rulesUrl!, completion: { loadedRules in
            XCTAssertNil(loadedRules)
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 0.5)
        XCTAssertTrue(mockUnzipper.unzipCalled)
        XCTAssertTrue(cache.getCalled)
        XCTAssertFalse(cache.setCalled)
    }

    // This serves as a functional test right now which uses the actual unzipping and temporary directory work
    func testLoadRulesFromUrlNoCache() {
        // Use the actual rules unzipper for integration testing purposes
        let rulesDownloaderReal = RulesDownloader(fileUnzipper: FileUnzipper())
        ServiceProvider.shared.networkService = MockRulesDownloaderNetworkService(response: .success)
        let expectation = XCTestExpectation(description: "RulesDownloader invokes callback with rules")
        var rules: Data?

        rulesDownloaderReal.loadRulesFromUrl(rulesUrl: RulesDownloaderTests.rulesUrl!, completion: { loadedRules in
            rules = loadedRules
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 0.5)
        XCTAssertNotNil(rules)
    }
}
