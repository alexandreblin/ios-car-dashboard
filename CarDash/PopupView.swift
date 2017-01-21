//
//  PopupView.swift
//  CarDash
//
//  Created by Alexandre Blin on 03/07/2016.
//  Copyright © 2016 Alexandre Blin. All rights reserved.
//

import UIKit

/// A popup containing a message and an optional image
class PopupView: BlurredView {
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView?

    @IBOutlet private weak var imageConstraint: NSLayoutConstraint?
    @IBOutlet private weak var textOnlyConstraint: NSLayoutConstraint?

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 703, height: 336)
    }

    func setImage(_ image: UIImage?) {
        guard let imageView = imageView else {
            return
        }

        if let image = image {
            imageView.image = image
            imageView.isHidden = false
        } else {
            imageView.isHidden = true
        }

        setNeedsUpdateConstraints()
    }

    override func updateConstraints() {
        super.updateConstraints()

        guard let imageView = imageView else {
            return
        }

        imageConstraint?.isActive = !imageView.isHidden
        textOnlyConstraint?.isActive = imageView.isHidden
    }
}
