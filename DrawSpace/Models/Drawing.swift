//
//  Drawing.swift
//  DrawSpace
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import RealmSwift

class Image: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var resourceUrl: String = ""
    @objc dynamic var localFilename: String = ""
}

class Color: Object {
    @objc dynamic var red: Double = 0
    @objc dynamic var green: Double = 0
    @objc dynamic var blue: Double = 0
    @objc dynamic var alpha: Double = 0
}

extension Color {
    func toJSON() -> [String: Double] {
        return [
            "red": red,
            "green": green,
            "blue": blue,
            "alpha": alpha,
        ]
    }

    static func fromJSON(_ json: [String: Double]) -> Color? {
        guard let red = json["red"],
            let green = json["green"],
            let blue = json["blue"],
            let alpha = json["alpha"] else {
                assertionFailure("Failed to deserialize color from json: \(json)")
                return nil
        }

        let color = Color()
        color.red = red
        color.green = green
        color.blue = blue
        color.alpha = alpha
        return color
    }
}

class Point: Object {
    @objc dynamic var x: Double = 0
    @objc dynamic var y: Double = 0
}

extension Point {
    var cgPoint: CGPoint {
        return CGPoint(x: x, y: y)
    }

    func toJSON() -> [String: Double] {
        return [
            "x": x,
            "y": y,
        ]
    }

    static func fromJSON(_ json: [String: Double]) -> Point? {
        guard let x = json["x"], let y = json["y"] else {
            assertionFailure("Failed to deserialize point from json: \(json)")
            return nil
        }

        let point = Point()
        point.x = x
        point.y = y
        return point
    }
}

extension List where List.Element: Point {
    func toJSON() -> Array<[String: Double]> {
        return map { $0.toJSON() }
    }
}

class DrawStep: Object {
    var points = List<Point>()
    @objc dynamic var color: Color? = Color()
    @objc dynamic var strokeWidth: Double = 16
    @objc dynamic var durationMark: Double = 0
}

extension DrawStep {
    func toJSON() -> [String: Any] {
        return [
            "points": points.toJSON(),
            "color": (color ?? Color()).toJSON(),
            "strokeWidth": strokeWidth,
            "durationMark": durationMark,
        ]
    }

    static func fromJSON(_ json: [String: Any]) -> DrawStep? {
        guard let points = json["points"] as? Array<[String: Double]>,
            let color = json["color"] as? [String: Double],
            let strokeWidth = json["strokeWidth"] as? Double,
            let durationMark = json["durationMark"] as? Double else {
                assertionFailure("Failed to deserialize step from json: \(json)")
                return nil
        }

        let pointsList = List<Point>()
        pointsList.append(objectsIn: points.compactMap { Point.fromJSON($0) })

        let step = DrawStep()
        step.points = pointsList
        step.color = Color.fromJSON(color)
        step.strokeWidth = strokeWidth
        step.durationMark = durationMark
        return step
    }
}

extension DrawStep {
    var cgColor: CGColor? {
        guard let stepColor = color else {
            assertionFailure("Missing step color")
            return nil
        }

        let uiColor = UIColor(red: CGFloat(stepColor.red),
                              green: CGFloat(stepColor.green),
                              blue: CGFloat(stepColor.blue),
                              alpha: CGFloat(stepColor.alpha))

        return uiColor.cgColor
    }

    static func from(color: CGColor, strokeWidth: Double, durationMark: Double, points: [CGPoint]) -> DrawStep? {
        assert(points.count > 0, "Expected there to be more than zero points")

        guard let colorComponents = color.components else {
            assertionFailure("Failed to get color components")
            return nil
        }

        let stepColor = Color()
        stepColor.red = Double(colorComponents[safe: 0] ?? 1)
        stepColor.green = Double(colorComponents[safe: 1] ?? 1)
        stepColor.blue = Double(colorComponents[safe: 2] ?? 1)
        stepColor.alpha = Double(colorComponents[safe: 3] ?? 1)

        var stepPoints = [Point]()
        for point in points {
            let temp = Point()
            temp.x = Double(point.x)
            temp.y = Double(point.y)
            stepPoints.append(temp)
        }

        let step = DrawStep()
        step.color = stepColor
        step.strokeWidth = strokeWidth
        step.durationMark = durationMark
        step.points.append(objectsIn: stepPoints)

        return step
    }
}

extension List where List.Element: DrawStep {
    func toJSON() -> Array<[String: Any]> {
        return map { $0.toJSON() }
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
    @objc dynamic var drawingDurationSeconds: Double = 0
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
