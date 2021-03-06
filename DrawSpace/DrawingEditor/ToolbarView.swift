//
//  DrawView.swift
//  DrawSpace
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import UIKit

protocol ToolbarViewDelegate: class {
    func colorTapped(_ color: UIColor)
    func sliderMoved(value: Double)
}

class ToolbarView: UIView {

    // MARK: Private Properties
    
    private let colorViewBorderColor = UIColor.black.cgColor
    private let colorViewBorderWidth: CGFloat = 2

    private lazy var sliderView: UISlider = {
        let view = UISlider(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.minimumValue = 1
        view.maximumValue = 80
        view.value = 16
        view.isContinuous = false
        view.addTarget(self, action: #selector(sliderMoved), for: .valueChanged)
        return view
    }()

    private lazy var colorViews: [UIView] = {
        let colors: [UIColor] = [.red, .green, .blue, .purple, .orange, .white]
        return colors.map { color in
            let view = UIView(frame: .zero)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = color
            view.layer.borderColor = colorViewBorderColor
            view.layer.borderWidth = colorViewBorderWidth
            return view
        }
    }()

    private lazy var toolbarColorView: UIStackView = {
        let view = UIStackView(arrangedSubviews: colorViews)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.distribution = .equalSpacing
        view.alignment = .center
        return view
    }()

    // MARK: Public Properties
    
    weak var delegate: ToolbarViewDelegate?
    
    // MARK: Initialization
    
    init() {
        super.init(frame: .zero)
        
        addSubview(sliderView)
        addSubview(toolbarColorView)
        
        NSLayoutConstraint.activate([
            toolbarColorView.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor),
            toolbarColorView.heightAnchor.constraint(equalTo: safeAreaLayoutGuide.heightAnchor, multiplier: 0.5),
            toolbarColorView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: 10),

            sliderView.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor),
            sliderView.heightAnchor.constraint(equalTo: safeAreaLayoutGuide.heightAnchor, multiplier: 0.5),
            sliderView.bottomAnchor.constraint(equalTo: toolbarColorView.topAnchor),
        ])

        let colorViewSize = Theme.toolbarView.colorViewSize
        colorViews.forEach { view in
            NSLayoutConstraint.activate([
                view.heightAnchor.constraint(equalToConstant: colorViewSize.height),
                view.widthAnchor.constraint(equalToConstant: colorViewSize.width)
            ])

            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(colorViewTapped))
            view.addGestureRecognizer(tapGestureRecognizer)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Private Methods
    
    @objc func colorViewTapped(sender: UITapGestureRecognizer) {
        guard let color = sender.view?.backgroundColor else {
            assertionFailure("Expected a color view as sender")
            return
        }
        
        if sender.state == .ended {
            delegate?.colorTapped(color)
        }
    }

    @objc func sliderMoved(sender: UISlider) {
        delegate?.sliderMoved(value: Double(sender.value))
    }
}
