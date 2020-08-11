//
//  Drawing.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import RealmSwift

class Image: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var contentType: String = ""
    @objc dynamic var resourceUrl: String = ""
    @objc dynamic var smallUrl: String = ""
    @objc dynamic var mediumUrl: String = ""
    @objc dynamic var largeUrl: String = ""
    @objc dynamic var localUrl: String = ""
}

class Color: Object {
    @objc dynamic var red: Double = 0
    @objc dynamic var green: Double = 0
    @objc dynamic var blue: Double = 0
    @objc dynamic var alpha: Double = 0
}

class Point: Object {
    @objc dynamic var x: Double = 0
    @objc dynamic var y: Double = 0
}

class DrawStep: Object {
    @objc dynamic var strokeWidth: Double = 16
    @objc dynamic var color: Color? = Color()
    @objc dynamic var start: Point? = Point()
    @objc dynamic var end: Point? = nil
}

extension DrawStep {
    var cgColor: CGColor {
        guard let stepColor = color else {
            assertionFailure("Missing step color")
            return UIColor.white.cgColor
        }

        let uiColor = UIColor(red: CGFloat(stepColor.red),
                              green: CGFloat(stepColor.green),
                              blue: CGFloat(stepColor.blue),
                              alpha: CGFloat(stepColor.alpha))

        return uiColor.cgColor
    }

    var startPoint: CGPoint {
        guard let point = start else {
            assertionFailure("Failed to get start point from DrawStep")
            return .zero
        }

        return CGPoint(x: point.x, y: point.y)
    }

    var endPoint: CGPoint? {
        guard let point = end else {
            return nil
        }

        return CGPoint(x: point.x, y: point.y)
    }
}

class Drawing: Object {
    enum UploadState: String {
        case sending
        case failed
        case success
    }
    
    @objc dynamic var id: Int = -1
    @objc dynamic var createdAt = Date()
    @objc dynamic var width: Int = 0
    @objc dynamic var height: Int = 0
    @objc dynamic var drawingDurationSeconds: Int = 0
    @objc dynamic var uploadState: String = UploadState.sending.rawValue
    @objc dynamic var image: Image?
    var steps = List<DrawStep>()
}

extension Drawing {
    var localImageData: Data? {
        guard let imageLocalUrl = image?.localUrl,
            !imageLocalUrl.isEmpty,
            let url = URL(string: imageLocalUrl),
            let data = try? Data(contentsOf: url) else {
                return nil
        }
        
        return data
    }
}
