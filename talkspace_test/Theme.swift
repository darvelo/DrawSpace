//
//  Theme.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import UIKit

// TODO: This should be passed down through every view controller,
//       rather than referenced explicitly.
struct Theme {
    struct ToolbarView {
        let widthFactor: CGFloat = 0.9
        let height: CGFloat = 70
        let bottomOffset: CGFloat = -20
        let colorViewSize = CGSize(width: 50, height: 50)
    }

    static let toolbarView = ToolbarView()
}
