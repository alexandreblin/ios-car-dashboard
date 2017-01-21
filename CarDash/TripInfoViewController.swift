//
//  TripInfoViewController.swift
//  CarDash
//
//  Created by Alexandre Blin on 12/06/2016.
//  Copyright © 2016 Alexandre Blin. All rights reserved.
//

import UIKit

/// View controller displaying the trip computer data and
/// a live fuel usage graph.
class TripInfoViewController: CarObservingViewController {
    @IBOutlet private weak var tripInfoContainerView: UIView!
    @IBOutlet private weak var fuelUsageGraph: GraphView!

    private var instantView: TripInfoView!
    private var trip1View: TripInfoView!
    private var trip2View: TripInfoView!

    private var tripInfoViews: [TripInfoView] = []

    /// Timer which fills the graph with the last received data from the bus
    /// in case we don't get any new data from the car.
    private var fuelGraphIdleTimer: Timer? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear

        fuelUsageGraph.maximumNumberOfValues = 10
        fuelUsageGraph.maximumScale = 20

        instantView = TripInfoView.view(withTitle: "Infos instantannées", mode: .instant)
        trip1View = TripInfoView.view(withTitle: "Infos trajet 1", mode: .trip)
        trip2View = TripInfoView.view(withTitle: "Infos trajet 2", mode: .trip)

        tripInfoViews = [instantView, trip1View, trip2View]

        for view in tripInfoViews {
            view.translatesAutoresizingMaskIntoConstraints = false
            tripInfoContainerView.addSubview(view)

            tripInfoContainerView.addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view": view])
            )

            tripInfoContainerView.addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view": view])
            )
        }

        carInfoPropertyChanged(carInfo, property: .tripInfoMode)
        updateView(trip1View, tripInfo: carInfo.tripInfo1)
        updateView(trip2View, tripInfo: carInfo.tripInfo2)
        updateViewWithInstantInfo(carInfo.instantInfo)
    }

    @objc private func fillGraph() {
        fuelUsageGraph.fillWithLastValue()
    }

    override func carInfoPropertyChanged(_ carInfo: CarInfo, property: CarInfo.Property) {
        if property == .tripInfo1 {
            updateView(trip1View, tripInfo: carInfo.tripInfo1)
        } else if property == .tripInfo2 {
            updateView(trip2View, tripInfo: carInfo.tripInfo2)
        } else if property == .instantInfo {
            updateViewWithInstantInfo(carInfo.instantInfo)
        } else if property == .tripInfoMode {
            UIView.transition(with: tripInfoContainerView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                for view in self.tripInfoViews {
                    view.isHidden = self.tripInfoViews.index(of: view) != self.carInfo.tripInfoMode.rawValue
                }
            }, completion: nil)
        }
    }

    private func updateViewWithInstantInfo(_ instantInfo: CarInfo.InstantInfo) {
        let normalizedFuelUsage = instantInfo.fuelUsage < 0 ? 0 : instantInfo.fuelUsage

        instantView.label1?.attributedText = attributedStringWithInteger(instantInfo.autonomy, suffix: "km")
        instantView.label2?.attributedText = attributedStringWithDouble(normalizedFuelUsage, suffix: "l/100")

        fuelUsageGraph.add(value: CGFloat(normalizedFuelUsage))
        fuelGraphIdleTimer?.invalidate()
        fuelGraphIdleTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(TripInfoViewController.fillGraph), userInfo: nil, repeats: true)
    }

    private func updateView(_ tripInfoView: TripInfoView, tripInfo: CarInfo.TripInfo) {
        tripInfoView.label1?.attributedText = attributedStringWithInteger(tripInfo.distance, suffix: "km")
        tripInfoView.label2?.attributedText = attributedStringWithDouble(tripInfo.averageFuelUsage, suffix: "l/100")
        tripInfoView.label3?.attributedText = attributedStringWithInteger(tripInfo.averageSpeed, suffix: "km/h")

        // align right only if we have a value, else center the dashes ('---')
        if tripInfo.averageFuelUsage < 0 {
            tripInfoView.label2?.textAlignment = .center
        } else {
            tripInfoView.label2?.textAlignment = .right
        }
    }

    private func attributedStringWithInteger(_ integer: Int, suffix: String?) -> NSAttributedString {
        if integer < 0 {
            return attributedStringWithValue("---", suffix: nil)
        }

        return attributedStringWithValue("\(integer)", suffix: suffix)
    }

    private func attributedStringWithDouble(_ double: Double, suffix: String?) -> NSAttributedString {
        if double < 0 {
            return attributedStringWithValue("---", suffix: nil)
        }

        return attributedStringWithValue(String(format: "%.1f", double), suffix: suffix)
    }

    /// Creates an attributed string with a value printed in white and a suffix (unit)
    /// printed in a smaller font in gray
    ///
    /// - Parameters:
    ///   - value: The value to display
    ///   - suffix: The suffix to display (e.g. "km/h")
    /// - Returns: An NSAttributedString
    private func attributedStringWithValue(_ value: String, suffix: String?) -> NSAttributedString {
        let defaultAttrs: [String: AnyObject] = [
            NSFontAttributeName: UIFont(name: "MC360", size: 44)!,
            NSForegroundColorAttributeName: UIColor(white: 0.87, alpha: 1)
        ]

        let smallAttrs: [String: AnyObject] = [
            NSFontAttributeName: UIFont(name: "MC360", size: 30)!,
            NSForegroundColorAttributeName: UIColor(white: 0.60, alpha: 1)
        ]

        let labelText = NSMutableAttributedString()

        labelText.append(NSAttributedString(string: value, attributes: defaultAttrs))

        if let suffix = suffix {
            labelText.append(NSAttributedString(string: " \(suffix)", attributes: smallAttrs))
        }

        return labelText
    }
}
