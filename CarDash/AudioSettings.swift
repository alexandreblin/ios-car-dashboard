//
//  AudioSettings.swift
//  CarDash
//
//  Created by Alexandre Blin on 18/06/2016.
//  Copyright © 2016 Alexandre Blin. All rights reserved.
//

import Foundation

/// Represents audio equalizer settings
struct AudioSettings: CustomStringConvertible, Equatable {
    enum EqualizerSetting: String {
        case none = "Aucun"
        case popRock = "Pop-Rock"
        case vocals = "Voix"
        case techno = "Techno"
        case classical = "Classique"
        case jazzBlues = "Jazz-Blues"

        static let allSettings = [none, popRock, vocals, techno, classical, jazzBlues]
    }

    enum Mode {
        case none
        case frontRearBalance
        case leftRightBalance
        case automaticVolume
        case equalizer
        case bass
        case treble
        case loudness
    }

    let activeMode: Mode

    let frontRearBalance: Int
    let leftRightBalance: Int
    let automaticVolume: Bool
    let equalizer: EqualizerSetting
    let bass: Int
    let treble: Int
    let loudness: Bool

    var description: String {
        return "AudioSettings(\nactiveMode: \(activeMode),\nfrontRearBalance: \(frontRearBalance),\nleftRightBalance: \(leftRightBalance),\nautomaticVolume: \(automaticVolume),\nequalizer: \(equalizer),\nbass: \(bass),\ntreble: \(treble),\nloudness: \(loudness)\n)"
    }
}

func == (lhs: AudioSettings, rhs: AudioSettings) -> Bool {
    return
        lhs.activeMode == rhs.activeMode &&
        lhs.frontRearBalance == rhs.frontRearBalance &&
        lhs.leftRightBalance == rhs.leftRightBalance &&
        lhs.automaticVolume == rhs.automaticVolume &&
        lhs.equalizer == rhs.equalizer &&
        lhs.bass == rhs.bass &&
        lhs.treble == rhs.treble &&
        lhs.loudness == rhs.loudness
}
