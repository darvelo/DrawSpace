//
//  Collection+SafeIndex.swift
//  DrawSpace
//
//  Created by David Arvelo on 8/11/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import Foundation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
