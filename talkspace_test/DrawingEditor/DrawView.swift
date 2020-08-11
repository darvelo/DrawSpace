//
//  DrawView.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/11/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import UIKit

class DrawView: UIView {

    // MARK: Initialization

    init() {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public Methods

    func draw(steps: [DrawStep], imageBuffer: UIImage?) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0)

        guard let context = UIGraphicsGetCurrentContext() else {
            assertionFailure("Failed to get current graphics context")
            return nil
        }

        context.setFillColor(UIColor.white.cgColor)
        context.fill(bounds)

        // Draw previous buffer first
        if let imageBuffer = imageBuffer {
            imageBuffer.draw(in: bounds)
        }

        for step in steps {
            guard var currentPoint = step.points.first else {
                assertionFailure("Couldn't get the first point")
                return nil
            }

            if step.points.count == 1 {
                drawDot(at: currentPoint.cgPoint,
                        color: step.cgColor,
                        radius: CGFloat(step.strokeWidth / 2),
                        in: context)
            } else {
                let nextPoints = step.points.dropFirst()

                for nextPoint in nextPoints {
                    drawLine(from: currentPoint.cgPoint,
                             to: nextPoint.cgPoint,
                             color: step.cgColor,
                             strokeWidth: CGFloat(step.strokeWidth),
                             in: context)
                    currentPoint = nextPoint
                }
            }
        }

        // Grab updated buffer and return it
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    private func drawDot(at point: CGPoint, color: CGColor, radius: CGFloat, in context: CGContext) {
        context.setFillColor(color)
        context.addArc(center: point,
                       radius: radius,
                       startAngle: 0,
                       endAngle: 2 * CGFloat.pi,
                       clockwise: true)
        context.fillPath()
    }

    private func drawLine(from startPoint: CGPoint,
                          to endPoint: CGPoint,
                          color: CGColor,
                          strokeWidth: CGFloat,
                          in context: CGContext
    ) {
        // Configure
        context.setStrokeColor(color)
        context.setLineWidth(CGFloat(strokeWidth))
        context.setLineCap(.round)

        // Draw
        context.move(to: startPoint)
        context.addLine(to: endPoint)
        context.strokePath()
    }

}
