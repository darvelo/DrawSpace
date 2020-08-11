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
    @objc dynamic var localFilename: String = ""
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

    static func from(color: CGColor, startPoint: CGPoint, endPoint: CGPoint?) -> DrawStep? {
        guard let colorComponents = color.components else {
            assertionFailure("Failed to get color components")
            return nil
        }

        let stepColor = Color()
        stepColor.red = Double(colorComponents[safe: 0] ?? 1)
        stepColor.green = Double(colorComponents[safe: 1] ?? 1)
        stepColor.blue = Double(colorComponents[safe: 2] ?? 1)
        stepColor.alpha = Double(colorComponents[safe: 3] ?? 1)

        let start = Point()
        start.x = Double(startPoint.x)
        start.y = Double(startPoint.y)


        var end: Point?
        if let endPoint = endPoint {
            let temp = Point()
            temp.x = Double(endPoint.x)
            temp.y = Double(endPoint.y)
            end = temp
        }

        let step = DrawStep()
        step.color = stepColor
        step.start = start
        step.end = end

        return step
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
    @objc dynamic var drawingDurationSeconds: Int = 0
    @objc dynamic var width: Double = 0
    @objc dynamic var height: Double = 0
    @objc dynamic var uploadState: String = UploadState.sending.rawValue
    @objc dynamic var image: Image?
    var steps = List<DrawStep>()
}

extension Drawing {
    var localImageData: Data? {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first

        guard let image = image,
            !image.localFilename.isEmpty,
            let imageUrl = documentsPath?.appendingPathComponent(image.localFilename),
            let data = try? Data(contentsOf: imageUrl) else {
                return nil
        }
        
        return data
    }
}
