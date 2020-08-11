//
//  DrawView.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import UIKit

protocol ToolbarViewDelegate: class {
    func colorTapped(_ color: UIColor)
}

class ToolbarView: UIView {

    // MARK: Private Properties
    
    private let colorViewBorderColor = UIColor.black.cgColor
    private let colorViewBorderWidth: CGFloat = 2
    
    private lazy var redView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .red
        view.layer.borderColor = colorViewBorderColor
        view.layer.borderWidth = colorViewBorderWidth
        return view
    }()

    private lazy var greenView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .green
        view.layer.borderColor = colorViewBorderColor
        view.layer.borderWidth = colorViewBorderWidth
        return view
    }()

    private lazy var blueView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .blue
        view.layer.borderColor = colorViewBorderColor
        view.layer.borderWidth = colorViewBorderWidth
        return view
    }()
    
    private lazy var eraserView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.borderColor = colorViewBorderColor
        view.layer.borderWidth = colorViewBorderWidth
        return view
    }()
    
    private lazy var colorViews = [redView, greenView, blueView, eraserView]
    
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
        
        addSubview(toolbarColorView)
        
        let colorViewSize = Theme.toolbarView.colorViewSize
        
        NSLayoutConstraint.activate([
            toolbarColorView.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor),
            toolbarColorView.heightAnchor.constraint(equalTo: safeAreaLayoutGuide.heightAnchor),
            
            redView.heightAnchor.constraint(equalToConstant: colorViewSize.height),
            redView.widthAnchor.constraint(equalToConstant: colorViewSize.width),

            greenView.heightAnchor.constraint(equalToConstant: colorViewSize.height),
            greenView.widthAnchor.constraint(equalToConstant: colorViewSize.width),
            
            blueView.heightAnchor.constraint(equalToConstant: colorViewSize.height),
            blueView.widthAnchor.constraint(equalToConstant: colorViewSize.width),
            
            eraserView.heightAnchor.constraint(equalToConstant: colorViewSize.height),
            eraserView.widthAnchor.constraint(equalToConstant: colorViewSize.width),
        ])
        
        colorViews.forEach { view in
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
}