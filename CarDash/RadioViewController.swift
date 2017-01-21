//
//  RadioViewController.swift
//  CarDash
//
//  Created by Alexandre Blin on 12/06/2016.
//  Copyright © 2016 Alexandre Blin. All rights reserved.
//

import UIKit
import MarqueeLabel

/// View controller displaying the current radio station.
class RadioViewController: CarObservingViewController {
    @IBOutlet private weak var radioDescriptionVerticalSpaceConstraint: NSLayoutConstraint!

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: MarqueeLabel!
    @IBOutlet private weak var frequencyLabel: UILabel!
    @IBOutlet private weak var radioArtView: UIImageView!

    private var radioArtFound = false

    private let radioAliases = [
        "virgin": "europe2",
        "mfmradio": "mfm",
        "cannesr": "razur",
        "rcfnice": "rcf"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add perspective to radioArtView
        var rotationAndPerspectiveTransform = CATransform3DIdentity
        rotationAndPerspectiveTransform.m34 = 1.0 / -500
        rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, 25.0 * CGFloat(M_PI) / 180.0, 0.0, 1.0, 0.0)

        radioArtView.layer.transform = rotationAndPerspectiveTransform
        radioArtView.layer.allowsEdgeAntialiasing = true
        radioArtView.layer.minificationFilter = kCAFilterTrilinear
    }

    override func carInfoPropertyChanged(_ carInfo: CarInfo, property: CarInfo.Property) {
        if property == .radioName || property == .radioFrequency || property == .radioBandName {
            if property == .radioFrequency {
                // When changing stations, remove current radio logo
                radioArtFound = false
                UIView.transition(with: radioArtView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                    self.radioArtView.image = UIImage(named: "radioart_placeholder")
                }, completion: nil)
            }

            updateRadioLabels()
        } else if property == .radioDescription {
            setRadioDescription(carInfo.radioDescription)
        }
    }

    /// Sets and animate the radio description label.
    ///
    /// - Parameter description: The description string to set
    private func setRadioDescription(_ description: String?) {
        if let description = description {
            descriptionLabel.text = description

            UIView.animate(withDuration: 0.5, animations: {
                self.descriptionLabel.alpha = 1
                self.radioDescriptionVerticalSpaceConstraint.constant = 32
                self.view.layoutIfNeeded()
            })
        } else {
            UIView.animate(withDuration: 0.5, animations: {
                self.descriptionLabel.alpha = 0
                self.radioDescriptionVerticalSpaceConstraint.constant = -78
                self.view.layoutIfNeeded()
            })
        }
    }

    private func updateRadioLabels() {
        if let radioName = carInfo.radioName, let frequency = carInfo.radioFrequency, let bandName = carInfo.radioBandName {
            nameLabel.text = radioName
            frequencyLabel.text = "\(frequency) MHz – FM \(bandName)"

            let charactersToRemove = CharacterSet.alphanumerics.inverted
            let strippedRadioName = carInfo.radioName?.lowercased().components(separatedBy: charactersToRemove).joined(separator: "")

            if !radioArtFound {
                // Try to find the station logo
                if var strippedRadioName = strippedRadioName {
                    if let mapping = radioAliases[strippedRadioName] {
                        strippedRadioName = mapping
                    }

                    if let radioArt = UIImage(named: "radioart_\(strippedRadioName)") {
                        radioArtFound = true
                        UIView.transition(with: radioArtView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                            self.radioArtView.image = radioArt
                            }, completion: nil)
                    }
                }
            }
        } else {
            // No station name found, display the frequency instead of the name
            nameLabel.text = (carInfo.radioFrequency ?? "0.0") + " MHz"
            frequencyLabel.text = "FM " + (carInfo.radioBandName ?? "")

            // Force layout now because when changing frequency, we animate the hiding of the radio description
            // but we don't want to animate the frequency label (it looks ugly)
            view.layoutIfNeeded()
        }
    }
}
