//
//  SettingLabel.swift
//  CarDash
//
//  Created by Alexandre Blin on 02/07/2016.
//  Copyright © 2016 Alexandre Blin. All rights reserved.
//

import UIKit

/// A label representing a modifiable setting, with arrows on the side.
/// The arrows can be shown/hidden to represent selected/deselected state.
class SettingLabel: UILabel {
    /// Contains the possible strings the label can display to properly
    /// compute its bounds and prevent "jumping" when switching values
    var possibleLabels: [String] = []

    var arrowWidth: CGFloat = 3
    var arrowPadding: CGFloat = 10
    var arrowYOffset: CGFloat = 4

    var arrowVisible = true {
        didSet {
            setNeedsDisplay()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override var intrinsicContentSize: CGSize {
        let currentTextSize = text?.size(attributes: [NSFontAttributeName: font])

        var width: CGFloat = currentTextSize?.width ?? 0
        var height: CGFloat = currentTextSize?.height ?? 0

        for label in possibleLabels {
            let size = label.size(attributes: [NSFontAttributeName: font])

            width = max(width, size.width)
            height = max(height, size.height)
        }

        return CGSize(width: width + 2 * (height / 2.0 + arrowPadding + 5), height: height)
    }

    func animateToNewText(_ newText: String) {
        if newText == text {
            return
        }

        UIView.transition(with: self,
                                  duration: 0.2,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                    self.text = newText
            }, completion: nil)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        if arrowVisible {
            guard let context = UIGraphicsGetCurrentContext() else {
                return
            }

            let height = bounds.height - 2 * arrowPadding

            context.setStrokeColor(textColor.cgColor)
            context.setLineWidth(arrowWidth)

            context.setLineJoin(.round)
            context.setLineCap(.round)

            context.move(to: CGPoint(x: height / 2.0 + arrowPadding, y: arrowPadding + arrowYOffset))
            context.addLine(to: CGPoint(x: arrowPadding, y: bounds.height / 2.0 + arrowYOffset))
            context.addLine(to: CGPoint(x: height / 2.0 + arrowPadding, y: bounds.height - arrowPadding + arrowYOffset))

            context.strokePath()

            context.move(to: CGPoint(x: bounds.width - (height / 2.0 + arrowPadding), y: arrowPadding + arrowYOffset))
            context.addLine(to: CGPoint(x: bounds.width - arrowPadding, y: bounds.height / 2.0 + arrowYOffset))
            context.addLine(to: CGPoint(x: bounds.width - (height / 2.0 + arrowPadding), y: bounds.height - arrowPadding + arrowYOffset))

            context.strokePath()
        }
    }
}
