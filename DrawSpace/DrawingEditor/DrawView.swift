//
//  DrawView.swift
//  DrawSpace
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

    func draw(steps: [DrawStep], replay isReplay: Bool, imageBuffer: UIImage?, onStep stepHandler: @escaping ((UIImage?) -> Void), completion: (() -> Void)?) {
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0)

        guard let context = UIGraphicsGetCurrentContext() else {
            assertionFailure("Failed to get current graphics context")
            stepHandler(nil)
            UIGraphicsEndImageContext()
            completion?()
            return
        }

        context.setFillColor(UIColor.white.cgColor)
        context.fill(bounds)

        // Draw previous buffer first
        if let imageBuffer = imageBuffer {
            imageBuffer.draw(in: bounds)
        }

        var lastDurationMark: Double = 0

        for step in steps {
            lastDurationMark = step.durationMark
            draw(step: step, in: context, useDuration: isReplay, completion: stepHandler)
        }

        if isReplay {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(lastDurationMark * 1000))) {
                UIGraphicsEndImageContext()
                completion?()
            }
        } else {
            UIGraphicsEndImageContext()
            completion?()
        }
    }

    // MARK: Private Methods

    private func draw(step: DrawStep, in context: CGContext, useDuration: Bool, completion: @escaping ((UIImage?) -> Void)) {
        guard var currentPoint = step.points.first else {
            assertionFailure("Couldn't get the first point")
            completion(nil)
            return
        }

        let block: (() -> Void)
        if step.points.count == 1 {
            block = { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.drawDot(at: currentPoint.cgPoint,
                                   color: step.cgColor,
                                   radius: CGFloat(step.strokeWidth / 2),
                                   in: context)

                // Grab updated buffer and return it
                let image = UIGraphicsGetImageFromCurrentImageContext()
                completion(image)
            }
        } else {
            block = { [weak self] in
                guard let strongSelf = self else { return }
                let nextPoints = step.points.dropFirst()
                for nextPoint in nextPoints {
                    strongSelf.drawLine(from: currentPoint.cgPoint,
                                        to: nextPoint.cgPoint,
                                        color: step.cgColor,
                                        strokeWidth: CGFloat(step.strokeWidth),
                                        in: context)
                    currentPoint = nextPoint
                }

                // Grab updated buffer and return it
                let image = UIGraphicsGetImageFromCurrentImageContext()
                completion(image)
            }
        }

        if useDuration {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(step.durationMark * 1000)), execute: block)
        } else {
            block()
        }
    }

    private func drawDot(at point: CGPoint, color: CGColor, radius: CGFloat, in context: CGContext) {
        // Configure
        context.setFillColor(color)

        // Draw
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
