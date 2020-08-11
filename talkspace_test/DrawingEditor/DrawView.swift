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

    func draw(step: DrawStep, imageBuffer: UIImage?) -> UIImage? {
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

        if step.end == nil {
            drawDot(step, in: context)
        } else {
            drawLine(step, in: context)
        }

        // Grab updated buffer and return it
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    private func drawDot(_ step: DrawStep, in context: CGContext) {
        context.setFillColor(step.cgColor)
        context.addArc(center: step.startPoint,
                       radius: CGFloat(step.strokeWidth / 2),
                       startAngle: 0,
                       endAngle: 2 * CGFloat.pi,
                       clockwise: true)
        context.fillPath()
    }

    private func drawLine(_ step: DrawStep, in context: CGContext) {
        guard let endPoint = step.endPoint else {
            assertionFailure("Failed to get end point for line from DrawStep")
            return
        }

        let startPoint = step.startPoint

        // Configure
        context.setStrokeColor(step.cgColor)
        context.setLineWidth(CGFloat(step.strokeWidth))
        context.setLineCap(.round)

        // Draw
        context.move(to: startPoint)
        context.addLine(to: endPoint)
        context.strokePath()
    }

}
