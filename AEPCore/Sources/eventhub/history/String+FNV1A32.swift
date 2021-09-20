/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

/// 32-bit FNV hash
/// https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function
///
/// Online validator - https://md5calc.com/hash/fnv1a32?str=
///
extension String {
    func fnv1a32(_ hash: UInt32) -> UInt32 {
        let prime: UInt32 = 16777619
        let offset: UInt32 = 2166136261

        var hash: UInt32 = offset
        let chars = Array(self.utf8)

        for char in chars {
            hash = hash ^ UInt32(char)
            hash = hash &* prime
        }

        return hash
    }
}
