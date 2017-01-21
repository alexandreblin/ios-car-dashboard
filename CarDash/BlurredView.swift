//
//  BlurredView.swift
//  CarDash
//
//  Created by Alexandre Blin on 03/07/2016.
//  Copyright © 2016 Alexandre Blin. All rights reserved.
//

import UIKit

/// A view with rounded corners and a blurred translucent background
class BlurredView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupView()
    }

    func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        backgroundColor = UIColor.clear

        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        blurEffectView.frame = bounds

        addSubview(blurEffectView)
        sendSubview(toBack: blurEffectView)

        layer.cornerRadius = 10
        layer.masksToBounds = true
    }

    /// Adds the view to a superview and add constraints to
    /// center it vertically and horizontally
    ///
    /// - Parameter view: The superview to add the view to
    func addToView(_ view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(self)

        view.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: view,
            attribute: .centerX,
            multiplier: 1.0,
            constant: 0.0
            ))

        view.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: view,
            attribute: .centerY,
            multiplier: 1.0,
            constant: 0.0
            ))
    }
}
