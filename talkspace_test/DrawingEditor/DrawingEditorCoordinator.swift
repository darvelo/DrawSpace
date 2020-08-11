//
//  DrawingEditorCoordinator.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import UIKit

enum DrawingEditorCoordinatorEvent {
    case cancel
    case done(image: UIImage?)
}

protocol DrawingEditorCoordinatorDelegate: class {
    func handleDrawingEditorCoordinatorEvent(_: DrawingEditorCoordinatorEvent)
}

class DrawingEditorCoordinator: Coordinator, DrawingEditorViewControllerDelegate {

    // MARK: Private Properties

    private var currentColor = UIColor.red
    private var lastPanPoint: CGPoint?
    private var steps = [DrawStep]()
    
    private lazy var drawingEditorViewController: DrawingEditorViewController = {
        let vc = DrawingEditorViewController()
        vc.delegate = self
        return vc
    }()
    
    // MARK: Public Properties
    
    weak var delegate: DrawingEditorCoordinatorDelegate?
    lazy var rootViewController: UIViewController = drawingEditorViewController
    
    // MARK: Initialization
    
    init(drawing: Drawing?) {
        drawingEditorViewController.update(drawing: drawing)
    }
    
    // MARK: Coordinator
    
    func start() { }
    
    // MARK: DrawingEditorViewControllerDelegate
    
    func cancelTapped() {
        delegate?.handleDrawingEditorCoordinatorEvent(.cancel)
    }
    
    func doneTapped(image: UIImage?) {
        delegate?.handleDrawingEditorCoordinatorEvent(.done(image: image))
    }

    func handleColorChange(color: UIColor) {
        currentColor = color
    }

    func handleDrawTap(point: CGPoint) {
        assert(lastPanPoint == nil, "Expected lastPanPoint to be nil on draw tap")

        guard let colorComponents = currentColor.cgColor.components else {
            assertionFailure("Failed to get color components")
            return
        }

        let stepColor = Color()
        stepColor.red = Double(colorComponents[safe: 0] ?? 1)
        stepColor.green = Double(colorComponents[safe: 1] ?? 1)
        stepColor.blue = Double(colorComponents[safe: 2] ?? 1)
        stepColor.alpha = Double(colorComponents[safe: 3] ?? 1)

        let stepPoint = Point()
        stepPoint.x = Double(point.x)
        stepPoint.y = Double(point.y)

        let step = DrawStep()
        step.color = stepColor
        step.start = stepPoint

        steps.append(step)
        drawingEditorViewController.update(step: step)
    }

    func handleDrawPan(event: DrawPanEvent) {
    }
}
