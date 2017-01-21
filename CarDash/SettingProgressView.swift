//
//  SettingProgressView.swift
//  CarDash
//
//  Created by Alexandre Blin on 02/07/2016.
//  Copyright © 2016 Alexandre Blin. All rights reserved.
//

import UIKit

/// A view representing a progress bar, where 0 is in the center of the bar.
/// It's used to display values which can be positive or negative (such as
/// front/rear audio balance, bass/treble settings, etc...)
class SettingProgressView: UIView {
    var value: Double = 0 {
        didSet {
            updateTransform(animated: true)
        }
    }

    var maxAbsoluteValue = 9 {
        didSet {
            setNeedsLayout()
        }
    }

    var barColor = UIColor(red: 56.0/255.0, green: 120.0/255.0, blue: 138.0/255.0, alpha: 1.0)
    var barTrackColor = UIColor(red: 174.0/255.0, green: 174.0/255.0, blue: 174.0/255.0, alpha: 1.0)
    var activeBarColor = UIColor(red: 56.0/255.0, green: 144.0/255.0, blue: 190.0/255.0, alpha: 1.0)
    var activeBarTrackColor = UIColor(red: 213.0/255.0, green: 213.0/255.0, blue: 213.0/255.0, alpha: 1.0)

    var active: Bool = false {
        didSet {
            if active {
                barSubView.backgroundColor = activeBarColor
                layer.backgroundColor = activeBarTrackColor.cgColor
            } else {
                barSubView.backgroundColor = barColor
                layer.backgroundColor = barTrackColor.cgColor
            }
        }
    }

    private var barSubView: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupView()
    }

    func setupView() {
        layer.cornerRadius = 5
        layer.masksToBounds = true
        layer.backgroundColor = barTrackColor.cgColor

        barSubView = UIView()
        barSubView.backgroundColor = barColor
        barSubView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(barSubView)

        addConstraint(NSLayoutConstraint(
            item: barSubView,
            attribute: .leading,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerX,
            multiplier: 1.0,
            constant: 0.0))

        addConstraint(NSLayoutConstraint(
            item: barSubView,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: self,
            attribute: .trailing,
            multiplier: 1.0,
            constant: 0.0))

        addConstraint(NSLayoutConstraint(
            item: barSubView,
            attribute: .top,
            relatedBy: .equal,
            toItem: self,
            attribute: .top,
            multiplier: 1.0,
            constant: 0.0))

        addConstraint(NSLayoutConstraint(
            item: barSubView,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: self,
            attribute: .bottom,
            multiplier: 1.0,
            constant: 0.0))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateTransform(animated: false)
    }

    private func updateTransform(animated: Bool) {
        let progress = CGFloat(value) / CGFloat(maxAbsoluteValue)

        UIView.animate(withDuration: animated ? 0.5 : 0, animations: {
            var transform = CGAffineTransform.identity

            transform = transform.translatedBy(x: -self.barSubView.bounds.width/2.0, y: 0)

            // can't have a 0% transform scale so we cap the minimum scale to 0.01
            transform = transform.scaledBy(x: abs(progress) < 0.01 ? 0.01 : progress, y: 1.0)

            transform = transform.translatedBy(x: self.barSubView.bounds.width/2.0, y: 0)

            self.barSubView.transform = transform
        })
    }
}
