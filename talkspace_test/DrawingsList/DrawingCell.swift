//
//  DrawingCell.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import UIKit
import RealmSwift
import SDWebImage


class DrawingCell: UITableViewCell {
    
    // MARK: Private Properties
    
    private var realmNotificationToken: NotificationToken?
    private var realmImageNotificationToken: NotificationToken?
    
    private lazy var drawingImageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .blue
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    private lazy var labelView: UILabel = {
        let view = UILabel(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.numberOfLines = 3
        view.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return view
    }()
    
    private lazy var uploadStateView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .gray
        return view
    }()
    
    private lazy var circleIndicatorView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12
        view.layer.backgroundColor = UIColor.black.cgColor
        view.backgroundColor = .blue
        return view
    }()
    
    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.color = .black
        return view
    }()
    
    // MARK: Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .lightGray
        addSubview(drawingImageView)
        addSubview(labelView)
        addSubview(uploadStateView)
        addSubview(activityIndicatorView)
        addSubview(circleIndicatorView)
        
        [
            drawingImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            drawingImageView.topAnchor.constraint(equalTo: topAnchor),
            drawingImageView.heightAnchor.constraint(equalTo: heightAnchor),
            drawingImageView.widthAnchor.constraint(equalTo: heightAnchor),
           
            uploadStateView.trailingAnchor.constraint(equalTo: trailingAnchor),
            uploadStateView.topAnchor.constraint(equalTo: topAnchor),
            uploadStateView.heightAnchor.constraint(equalTo: heightAnchor),
            uploadStateView.widthAnchor.constraint(equalTo: heightAnchor),
            
            activityIndicatorView.heightAnchor.constraint(equalTo: uploadStateView.heightAnchor, multiplier: 0.5),
            activityIndicatorView.widthAnchor.constraint(equalTo: uploadStateView.widthAnchor, multiplier: 0.5),
            activityIndicatorView.centerYAnchor.constraint(equalTo: uploadStateView.centerYAnchor),
            activityIndicatorView.centerXAnchor.constraint(equalTo: uploadStateView.centerXAnchor),
            
            circleIndicatorView.heightAnchor.constraint(equalToConstant: 24),
            circleIndicatorView.widthAnchor.constraint(equalToConstant: 24),
            circleIndicatorView.centerYAnchor.constraint(equalTo: uploadStateView.centerYAnchor),
            circleIndicatorView.centerXAnchor.constraint(equalTo: uploadStateView.centerXAnchor),

            labelView.leadingAnchor.constraint(equalTo: drawingImageView.trailingAnchor, constant: 10),
            labelView.trailingAnchor.constraint(equalTo: uploadStateView.leadingAnchor, constant: -10),
            labelView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ].forEach { $0.isActive = true }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        invalidateRealmNotificationToken()
    }
    
    // MARK: Public Methods
    
    func configure(drawing: Drawing) {
        labelView.text = "Created: \(drawing.createdAt)"
        observeNoteUploadState(drawing: drawing)
        setImage(from: drawing)
        setUploadState(state: drawing.uploadState)
    }
    
    // MARK: Private Methods
    
    private func invalidateRealmNotificationToken() {
        realmNotificationToken?.invalidate()
        realmNotificationToken = nil
        realmImageNotificationToken?.invalidate()
        realmImageNotificationToken = nil
    }
    
    private func observeNoteUploadState(drawing: Drawing) {
        invalidateRealmNotificationToken()
        realmNotificationToken = drawing.observe { [weak self] change in
            switch change {
            case .change(_, let properties):
                for property in properties {
                    if property.name == "uploadState", let state = property.newValue as? String {
                        self?.setUploadState(state: state)
                    }
                }
            case .error(let error):
                print("A Drawing change error occurred: \(error)")
                self?.invalidateRealmNotificationToken()
            case .deleted:
                self?.invalidateRealmNotificationToken()
            }
        }
        
        // Hacky perhaps, I think, to use two notification tokens when one might be enough.
        guard let image = drawing.image else { return }
        realmImageNotificationToken = image.observe { [weak self] change in
            switch change {
            case .change(_, let properties):
                for property in properties {
                    if property.name == "localUrl" {
                        self?.setImage(from: drawing)
                    }
                }
            case .error(let error):
                print("A Drawing change error occurred: \(error)")
                self?.invalidateRealmNotificationToken()
            case .deleted:
                self?.invalidateRealmNotificationToken()
            }
        }
    }

    private func setImage(from drawing: Drawing) {
        if let smallUrl = drawing.image?.smallUrl, !smallUrl.isEmpty {
            drawingImageView.sd_setImage(with: URL(string: smallUrl), placeholderImage: nil)
            return
        }
        
        guard let data = drawing.localImageData,
            let image = UIImage(data: data) else {
                drawingImageView.image = nil
                return
        }
        
        drawingImageView.image = image
    }
    
    private func setUploadState(state: String) {
        let uploadState = Drawing.UploadState(rawValue: state) ?? .failed
        
        switch uploadState {
        case .sending:
            activityIndicatorView.startAnimating()
            circleIndicatorView.isHidden = true
        case .success, .failed:
            circleIndicatorView.layer.backgroundColor = (uploadState == .success) ? UIColor.green.cgColor : UIColor.red.cgColor
            activityIndicatorView.stopAnimating()
            circleIndicatorView.isHidden = false
        }
    }
}
