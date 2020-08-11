//
//  DrawingEditorViewController.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import UIKit

enum DrawPanEvent {
    case start(point: CGPoint)
    case move(point: CGPoint)
    case end(point: CGPoint)
}

protocol DrawingEditorViewControllerDelegate: class {
    func cancelTapped()
    func replayTapped()
    func doneTapped(image: UIImage?, canvasSize: CGSize)
    func handleDrawTap(point: CGPoint)
    func handleColorChange(color: UIColor)
    func handleStrokeWidthChange(strokeWidth: Double)
    func handleDrawPan(event: DrawPanEvent)
}

class DrawingEditorViewController: UIViewController, ToolbarViewDelegate {

    // MARK: Private Poperties

    private var drawing: Drawing?
    private var imageBuffer: UIImage?

    private lazy var imageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var toolbarView: ToolbarView = {
        let view = ToolbarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()

    private lazy var drawView: DrawView = {
        let view = DrawView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: Public Properties

    weak var delegate: DrawingEditorViewControllerDelegate?

    // MARK: Initialization

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped)),
                                              UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(replayTapped))]

        view.addSubview(imageView)
        view.addSubview(drawView)
        view.addSubview(toolbarView)

        drawView.backgroundColor = .clear
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor),
            imageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),

            drawView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            drawView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor),
            drawView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            drawView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),

            toolbarView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: Theme.toolbarView.widthFactor),
            toolbarView.heightAnchor.constraint(equalToConstant: Theme.toolbarView.height),
            toolbarView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            toolbarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: Theme.toolbarView.bottomOffset),
        ])

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        drawView.addGestureRecognizer(tapGestureRecognizer)

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        drawView.addGestureRecognizer(panGestureRecognizer)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let drawing = drawing else { return }
        drawSteps(steps: Array(drawing.steps), replay: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.cancelTapped()
    }

    // MARK: ToolbarViewDelegate

    func colorTapped(_ color: UIColor) {
        delegate?.handleColorChange(color: color)
    }

    func sliderMoved(value: Double) {
        delegate?.handleStrokeWidthChange(strokeWidth: value)
    }

    // MARK: Public Methods

    func update(drawing: Drawing) {
        self.drawing = drawing
    }

    func update(step: DrawStep) {
        drawSteps(steps: [step], replay: false)
    }

    func replay(steps: [DrawStep], completion: @escaping (() -> Void)) {
        imageBuffer = nil
        imageView.image = nil
        drawSteps(steps: steps, replay: true, completion: completion)
    }

    // MARK: Private Methods

    private func drawSteps(steps: [DrawStep], replay: Bool, completion: (() -> Void)? = nil) {
        autoreleasepool { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.drawView.draw(steps: steps, replay: replay, imageBuffer: strongSelf.imageBuffer, onStep: { [weak self] buffer in
                guard let strongSelf = self else { return }
                strongSelf.imageBuffer = buffer
                strongSelf.imageView.image = buffer
            },
            completion: completion)
        }
    }

    // MARK: Actions

    @objc private func cancelTapped() {
        delegate?.cancelTapped()
    }

    @objc private func replayTapped() {
        delegate?.replayTapped()
    }

    @objc private func doneTapped() {
        delegate?.doneTapped(image: imageBuffer, canvasSize: view.bounds.size)
    }

    @objc private func handleTap(sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }

        let point = sender.location(in: sender.view)
        delegate?.handleDrawTap(point: point)
    }

    @objc private func handlePan(sender: UIPanGestureRecognizer) {
        let point = sender.location(in: sender.view)
        switch sender.state {
        case .began:
            delegate?.handleDrawPan(event: .start(point: point))
        case .changed:
            delegate?.handleDrawPan(event: .move(point: point))
        case .ended:
            delegate?.handleDrawPan(event: .end(point: point))
        case .failed:
            delegate?.handleDrawPan(event: .end(point: point))
        case .possible:
            break
        case .cancelled:
            print("Pan canceled")
        @unknown default:
            print("Unknown pan gesture state")
        }
    }
}
