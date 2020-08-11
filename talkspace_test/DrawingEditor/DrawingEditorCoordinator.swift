//
//  DrawingEditorCoordinator.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import UIKit
import RealmSwift

enum DrawingEditorCoordinatorEvent {
    case cancel
    case create(drawing: Drawing,
                canvasSize: CGSize,
                duration: Double,
                steps: [DrawStep],
                image: UIImage?)
    case update(drawing: Drawing,
                canvasSize: CGSize,
                duration: Double,
                steps: [DrawStep],
                image: UIImage?)
}

protocol DrawingEditorCoordinatorDelegate: class {
    func handleDrawingEditorCoordinatorEvent(_: DrawingEditorCoordinatorEvent)
}

class DrawingEditorCoordinator: Coordinator, DrawingEditorViewControllerDelegate {

    // MARK: Private Properties

    private let store: Store
    private let isUpdate: Bool

    private var currentColor = UIColor.red
    private var currentStrokeWidth: Double = 16
    private var panPoints: [CGPoint]?
    private var startedAt = Date()

    private var createdAt = Date()
    private var drawingDurationSeconds: Double = 0
    private var steps = [DrawStep]()
    private lazy var drawing: Drawing = {
        let model = Drawing()
        model.createdAt = createdAt
        return model
    }()

    private lazy var drawingEditorViewController: DrawingEditorViewController = {
        let vc = DrawingEditorViewController()
        vc.delegate = self
        return vc
    }()
    
    // MARK: Public Properties
    
    weak var delegate: DrawingEditorCoordinatorDelegate?
    lazy var rootViewController: UIViewController = drawingEditorViewController
    
    // MARK: Initialization
    
    init(store: Store, drawing: Drawing?) {
        self.store = store
        self.isUpdate = drawing != nil

        if let drawing = drawing {
            self.steps = Array(drawing.steps)
            self.createdAt = drawing.createdAt
            self.drawingDurationSeconds = drawing.drawingDurationSeconds
            self.drawing = drawing
            drawingEditorViewController.update(drawing: drawing)
        }
    }
    
    // MARK: Coordinator
    
    func start() {
        startedAt = Date()
    }
    
    // MARK: DrawingEditorViewControllerDelegate
    
    func cancelTapped() {
        delegate?.handleDrawingEditorCoordinatorEvent(.cancel)
    }

    func replayTapped() {
        guard steps.count > 0 else { return }

        drawingEditorViewController.replay(steps: steps) { [weak self] in
            guard let strongSelf = self else { return }
            guard let lastStep = strongSelf.steps.last else {
                assertionFailure("Editor should have contained at least one step")
                return
            }

            // Allow the user to pick up where they left off after replaying,
            // so that time spent in the replay doesn't add to the total drawing duration.
            strongSelf.drawingDurationSeconds = lastStep.durationMark
            strongSelf.startedAt = Date()
        }
    }
    
    func doneTapped(image: UIImage?, canvasSize: CGSize) {
        guard steps.count > 0 else {
            delegate?.handleDrawingEditorCoordinatorEvent(.cancel)
            return
        }

        let event: DrawingEditorCoordinatorEvent
        if isUpdate {
            event = .update(drawing: drawing,
                            canvasSize: canvasSize,
                            duration: durationMark(),
                            steps: steps,
                            image: image)
        } else {
            event = .create(drawing: drawing,
                            canvasSize: canvasSize,
                            duration: durationMark(),
                            steps: steps,
                            image: image)
        }

        delegate?.handleDrawingEditorCoordinatorEvent(event)
    }

    func handleColorChange(color: UIColor) {
        currentColor = color
    }

    func handleStrokeWidthChange(strokeWidth: Double) {
        currentStrokeWidth = strokeWidth
    }

    func handleDrawTap(point: CGPoint) {
        assert(panPoints == nil, "Expected lastPanPoint to be nil on draw tap")

        guard let step = DrawStep.from(color: currentColor.cgColor,
                                       strokeWidth: currentStrokeWidth,
                                       durationMark: durationMark(),
                                       points: [point]) else {
            assertionFailure("Failed to create step for draw tap event")
            return
        }

        steps.append(step)
        drawingEditorViewController.update(step: step)
    }

    func handleDrawPan(event: DrawPanEvent) {
        switch event {
        case .start(let point):
            panPoints = [point]
        case .move(let point):
            assert(panPoints != nil, "Expected panPoints to be non-nil")
            assert(panPoints!.count >= 1, "Expected to have more than one pan point")

            guard let lastPanPoint = panPoints?.last else {
                assertionFailure("Expected to have a previous pan point")
                return
            }
            panPoints?.append(point)

            guard let intermediateStep = DrawStep.from(color: currentColor.cgColor,
                                                       strokeWidth: currentStrokeWidth,
                                                       durationMark: durationMark(),
                                                       points: [lastPanPoint, point]) else {
                assertionFailure("Failed to create intermediate step for pan move event")
                return
            }

            drawingEditorViewController.update(step: intermediateStep)
        case .end(let point):
            assert(panPoints != nil, "Expected panPoints to be non-nil")
            assert(panPoints!.count > 1, "Expected to have more than one pan point")

            let duration = durationMark()

            guard let lastPanPoint = panPoints?.last else {
                assertionFailure("Expected to have a previous pan point")
                return
            }

            panPoints?.append(point)

            guard let intermediateStep = DrawStep.from(color: currentColor.cgColor,
                                                       strokeWidth: currentStrokeWidth,
                                                       durationMark: duration,
                                                       points: [lastPanPoint, point]) else {
                assertionFailure("Failed to create intermediate step for pan end event")
                return
            }

            guard let points = panPoints else {
                assertionFailure("Expected panPoints to be non-nil")
                return
            }

            guard let step = DrawStep.from(color: currentColor.cgColor,
                                           strokeWidth: currentStrokeWidth,
                                           durationMark: duration,
                                           points: points) else {
                assertionFailure("Failed to create step for pan end event")
                return
            }

            drawingEditorViewController.update(step: intermediateStep)
            steps.append(step)
            panPoints = nil
        }
    }

    // MARK: Private Methods

    func durationMark() -> Double {
        let sessionDuration = Date().timeIntervalSince(startedAt)
        let durationMark = drawingDurationSeconds + sessionDuration
        return durationMark
    }
}
