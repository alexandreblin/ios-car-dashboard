//
//  AudioSettingsView.swift
//  CarDash
//
//  Created by Alexandre Blin on 03/07/2016.
//  Copyright © 2016 Alexandre Blin. All rights reserved.
//

import UIKit

/// A view representing the car's radio equalizer settings.
/// It contains various progress view and setting labels.
/// Only one setting is active at a time and is cycled by
/// pressing on a button on the radio. The values can then be
/// changed by pressing left/right arrows.
class AudioSettingsView: BlurredView {

    @IBOutlet weak var bassValue: UILabel!
    @IBOutlet weak var trebleValue: UILabel!
    @IBOutlet weak var frontRearBalanceValue: UILabel!
    @IBOutlet weak var leftRightBalanceValue: UILabel!

    @IBOutlet weak var bassBar: SettingProgressView!
    @IBOutlet weak var trebleBar: SettingProgressView!
    @IBOutlet weak var frontRearBalanceBar: SettingProgressView!
    @IBOutlet weak var leftRightBalanceBar: SettingProgressView!

    @IBOutlet weak var loudnessValue: SettingLabel!
    @IBOutlet weak var automaticVolumeValue: SettingLabel!
    @IBOutlet weak var equalizerValue: SettingLabel!

    var audioSettings: AudioSettings? {
        didSet {
            guard let audioSettings = audioSettings else {
                return
            }

            bassValue.text = String(audioSettings.bass)
            trebleValue.text = String(audioSettings.treble)
            frontRearBalanceValue.text = String(audioSettings.frontRearBalance)
            leftRightBalanceValue.text = String(audioSettings.leftRightBalance)

            bassBar.value = Double(audioSettings.bass)
            bassBar.active = audioSettings.activeMode == .bass

            trebleBar.value = Double(audioSettings.treble)
            trebleBar.active = audioSettings.activeMode == .treble

            frontRearBalanceBar.value = Double(audioSettings.frontRearBalance)
            frontRearBalanceBar.active = audioSettings.activeMode == .frontRearBalance

            leftRightBalanceBar.value = Double(audioSettings.leftRightBalance)
            leftRightBalanceBar.active = audioSettings.activeMode == .leftRightBalance

            loudnessValue.animateToNewText(audioSettings.loudness ? "Oui" : "Non")
            loudnessValue.arrowVisible = audioSettings.activeMode == .loudness

            automaticVolumeValue.animateToNewText(audioSettings.automaticVolume ? "Oui" : "Non")
            automaticVolumeValue.arrowVisible = audioSettings.activeMode == .automaticVolume

            equalizerValue.animateToNewText(audioSettings.equalizer.rawValue)
            equalizerValue.arrowVisible = audioSettings.activeMode == .equalizer
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        loudnessValue.possibleLabels = ["Oui", "Non"]
        automaticVolumeValue.possibleLabels = ["Oui", "Non"]
        equalizerValue.possibleLabels = AudioSettings.EqualizerSetting.allSettings.map { $0.rawValue }
    }
}
