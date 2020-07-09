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
import os.log

/// Implements a `LoggingService` which will send log message to Apple's unified logging system
class AEPLoggingService: LoggingService {
    private static let LOG_SUB_SYSTEM_NAME = "com.adobe.mobile.marketing.aep"
    private let cachedOSLogs = ThreadSafeDictionary<String, OSLog>()

    /// Generates or Retrieves an `OSLog` object by a label name
    /// - Parameter label: a name of label, which can be used to identify the consumer of this logging service
    /// - Returns: an `OSLog` object
    private func osLog(_ label: String) -> OSLog {
        if let osLog = cachedOSLogs[label] {
            return osLog
        } else {
            let osLog = OSLog(subsystem: AEPLoggingService.LOG_SUB_SYSTEM_NAME, category: label)
            cachedOSLogs[label] = osLog
            return osLog
        }
    }

    /// Converts `LogLevel` to Apple's `OSLogType`
    /// - Parameter logLevel: a `LogLevel` object
    /// - Returns: a `OSLogType` object
    private func osLogType(_ logLevel: LogLevel) -> OSLogType {
        switch logLevel {
        case .error:
            return .fault
        case .warning:
            return .error
        case .debug:
            return .debug
        case .trace:
            return .info
        }
    }

    // MARK: LoggingService

    func log(level: LogLevel, label: String, message: String) {
        os_log("%@", log: osLog(label), type: osLogType(level), message)
    }
}
