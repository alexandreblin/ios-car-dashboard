//
//  GraphView.swift
//  CarDash
//
//  Created by Alexandre Blin on 14/01/2017.
//  Copyright © 2017 Alexandre Blin. All rights reserved.
//

import UIKit

/// A view representing a curved line graph. It animates when a new value
/// is added by shifting the graph to the left.
class GraphView: UIView {
    /// Maximum number of values to display on the graph at the same time
    var maximumNumberOfValues: Int = 8 {
        didSet {
            values.removeAll()

            for _ in 0..<maximumNumberOfValues {
                values.append(0)
            }
        }
    }

    /// Maximum value on the y-axis
    var maximumScale: CGFloat = 15

    private static let translationAnimationKey = "translationAnimation"

    private var values = [CGFloat]()

    private var shapeLayer: CAShapeLayer!
    private var maskLayer: CAShapeLayer!

    private var gradientView: UIView!
    private var gradientLayer: CAGradientLayer! // gradient under the curve
    private var blackGradientLayer: CAGradientLayer! // black fading gradient at the end of graph

    private var isAnimating = false

    override func awakeFromNib() {
        super.awakeFromNib()

        clipsToBounds = true

        // Setup gradient view
        let gradientView = UIView(frame: bounds)
        gradientView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = [
            UIColor(colorLiteralRed: 0.84, green: 0.96, blue: 0.96, alpha: 0.75).cgColor,
            UIColor.black.cgColor
        ]

        gradientView.layer.addSublayer(gradientLayer)
        self.addSubview(gradientView)

        let maskLayer = CAShapeLayer()
        maskLayer.lineWidth = 4.0
        maskLayer.position = CGPoint.zero
        gradientView.layer.mask = maskLayer

        self.gradientView = gradientView
        self.gradientLayer = gradientLayer
        self.maskLayer = maskLayer

        // Setup shape layer
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor(white: 0.7, alpha: 1.0).cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 4.0
        shapeLayer.position = CGPoint.zero

        layer.addSublayer(shapeLayer)

        self.shapeLayer = shapeLayer

        let blackGradientLayer = CAGradientLayer()
        blackGradientLayer.frame = CGRect(x: 0, y: 0, width: 30, height: bounds.height)
        blackGradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.cgColor
        ]
        blackGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        blackGradientLayer.endPoint = CGPoint(x: 0.0, y: 0.5)
        layer.addSublayer(blackGradientLayer)

        self.blackGradientLayer = blackGradientLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = gradientView.bounds
        blackGradientLayer.frame = CGRect(x: 0, y: 0, width: blackGradientLayer.frame.width, height: bounds.height)
    }

    private func bezierPathForValues(withClose close: Bool = false) -> CGPath {
        precondition(values.count >= 2)

        let path = UIBezierPath()

        let padding: CGFloat = 3.0
        let viewHeight = bounds.height - 2 * padding
        let stepWidth = bounds.width / CGFloat(maximumNumberOfValues - 1)
        let curveForce = stepWidth / 3.0

        let lastFiveValues = values.suffix(5)

        let scaleMultiplier = viewHeight / lastFiveValues.reduce(maximumScale, max)

        var p1 = CGPoint(x: 0, y: viewHeight - padding - values[0] * scaleMultiplier)
        var p2: CGPoint = CGPoint.zero

        path.move(to: p1)

        for i in 1..<values.count {
            p2 = CGPoint(x: CGFloat(i) * stepWidth, y: viewHeight - padding - values[i] * scaleMultiplier)

            path.addCurve(to: p2,
                          controlPoint1: CGPoint(x: p1.x + curveForce, y: p1.y),
                          controlPoint2: CGPoint(x: p2.x - curveForce, y: p2.y))

            p1 = p2
        }

        if close {
            path.addLine(to: CGPoint(x: p2.x, y: viewHeight))
            path.addLine(to: CGPoint(x: 0, y: viewHeight))
            path.close()
        }

        return path.cgPath
    }

    func add(value: CGFloat) {
        if isAnimating {
            return
        }

        isAnimating = true

        values.append(value)

        if values.count < 2 {
            // No need to go further is we don't have more than 1 data point
            return
        }

        CATransaction.begin()

        CATransaction.setCompletionBlock {
            if self.values.count > self.maximumNumberOfValues {
                self.values.remove(at: 0)

                self.shapeLayer.path = self.bezierPathForValues()
                self.shapeLayer.removeAnimation(forKey: GraphView.translationAnimationKey)

                self.maskLayer.path = self.bezierPathForValues(withClose: true)
                self.maskLayer.removeAnimation(forKey: GraphView.translationAnimationKey)
            }

            self.isAnimating = false
        }

        let morphAnimation = CABasicAnimation(keyPath: "path")
        morphAnimation.duration = 0.2

        let path = bezierPathForValues()
        morphAnimation.fromValue = shapeLayer.path
        morphAnimation.toValue = path

        shapeLayer.add(morphAnimation, forKey: nil)

        if values.count > maximumNumberOfValues {
            let translationAnimation = CABasicAnimation(keyPath: "transform.translation.x")
            translationAnimation.duration = 0.2
            translationAnimation.fromValue = 0
            translationAnimation.toValue = -(bounds.width / CGFloat(maximumNumberOfValues - 1))
            translationAnimation.isRemovedOnCompletion = false
            translationAnimation.fillMode = kCAFillModeForwards

            shapeLayer.add(translationAnimation, forKey: GraphView.translationAnimationKey)
            maskLayer.add(translationAnimation, forKey: GraphView.translationAnimationKey)
        }

        CATransaction.commit()

        shapeLayer.path = path
        maskLayer.path = bezierPathForValues(withClose: true)
    }

    func fillWithLastValue() {
        add(value: values.last ?? 0)
    }
}
