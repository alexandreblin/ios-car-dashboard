//
//  CarInfo.swift
//  CarDash
//
//  Created by Alexandre Blin on 12/06/2016.
//  Copyright © 2016 Alexandre Blin. All rights reserved.
//

import Foundation

protocol CarInfoObserver: class {
    func carInfoPropertyChanged(_ carInfo: CarInfo, property: CarInfo.Property)
}

/// Class containing the current state of the car
class CarInfo {
    /// Returns the CarInfo singleton
    /// TODO: remove this and instantiate a unique CarInfo object
    /// at launch which will be passed along view controllers
    static let sharedInstance = CarInfo()

    /// Array of CarInfoObserver objects which will be notified
    /// when any property is changed
    private let observers = NSHashTable<AnyObject>.weakObjects()

    enum Property {
        case volume
        case temperature
        case radioSource
        case radioName
        case radioDescription
        case radioFrequency
        case radioBandName
        case infoMessage
        case tripInfoMode
        case tripInfo1
        case tripInfo2
        case instantInfo
        case carDoors
        case audioSettings
        case secretButton
    }

    enum CarRadioSource {
        case fmTuner
        case phone
        case aux
    }

    enum TripInfoMode: Int {
        case instant = 0
        case trip1 = 1
        case trip2 = 2
    }

    struct TripInfo {
        var distance: Int = 0
        var averageFuelUsage: Double = -1
        var averageSpeed: Int = -1
    }

    struct InstantInfo {
        var autonomy: Int = -1
        var fuelUsage: Double = -1
    }

    var volume: Int = 0 {
        didSet {
            if volume > 30 {
                volume = 30
            } else if volume < 0 {
                volume = 0
            }

            if oldValue != volume {
                notifyObservers(.volume)
            }
        }
    }

    var temperature: Int = 0 {
        didSet {
            if oldValue != temperature {
                notifyObservers(.temperature)
            }
        }
    }

    var radioSource: CarRadioSource = .fmTuner {
        didSet {
            if oldValue != radioSource {
                notifyObservers(.radioSource)
            }
        }
    }

    var radioName: String? = nil {
        didSet {
            radioName = radioName?.trimmingCharacters(
                in: CharacterSet.whitespaces)

            radioName = radioName?.characters.count == 0 ? nil : radioName

            if radioName != nil && originalRadioName == nil {
                originalRadioName = radioName
            }

            if radioName == nil {
                radioDescription = nil
            }

            if oldValue != radioName {
                notifyObservers(.radioName)
            }
        }
    }

    private var originalRadioName: String? = nil

    var radioDescription: String? = nil {
        didSet {
            radioDescription = radioDescription?.trimmingCharacters(
                in: CharacterSet.whitespaces)

            if oldValue != radioDescription {
                notifyObservers(.radioDescription)
            }
        }
    }

    var radioFrequency: String? = nil {
        didSet {
            if oldValue != radioFrequency {
                notifyObservers(.radioFrequency)
            }
        }
    }

    var radioBandName: String? = nil {
        didSet {
            if oldValue != radioBandName {
                notifyObservers(.radioBandName)
            }
        }
    }

    var infoMessage: String? = nil {
        didSet {
            if oldValue != infoMessage {
                notifyObservers(.infoMessage)
            }
        }
    }

    var tripInfoMode: TripInfoMode = .instant {
        didSet {
            if oldValue != tripInfoMode {
                notifyObservers(.tripInfoMode)
            }
        }
    }

    var instantInfo: InstantInfo = InstantInfo() {
        didSet {
            notifyObservers(.instantInfo)
        }
    }

    var tripInfo1: TripInfo = TripInfo() {
        didSet {
            notifyObservers(.tripInfo1)
        }
    }

    var tripInfo2: TripInfo = TripInfo() {
        didSet {
            notifyObservers(.tripInfo2)
        }
    }

    var carDoors: CarDoors = .None {
        didSet {
            if oldValue != carDoors {
                notifyObservers(.carDoors)
            }
        }
    }

    var audioSettings: AudioSettings = AudioSettings(activeMode: .none,
                                                     frontRearBalance: 0,
                                                     leftRightBalance: 0,
                                                     automaticVolume: false,
                                                     equalizer: .none,
                                                     bass: 0,
                                                     treble: 0,
                                                     loudness: false) {
        didSet {
            if oldValue != audioSettings {
                notifyObservers(.audioSettings)
            }
        }
    }

    var secretButton: Bool = false {
        didSet {
            if oldValue != secretButton {
                notifyObservers(.secretButton)
            }
        }
    }

    private var serialParser: SerialParser? = nil

    init() {
        // See CarInfo+SerialParserDelegate.swift for the
        // SerialParserDelegate protocol implementation
        self.serialParser = BluetoothSerialParser(delegate: self)
    }

    func addObserver(_ observer: CarInfoObserver) {
        observers.add(observer as AnyObject)
    }

    /// Notifies observers on the main thread when a property value change
    ///
    /// - Parameter property: The modified property name
    func notifyObservers(_ property: Property) {
        DispatchQueue.main.async {
            for observer in self.observers.allObjects {
                guard let observer = observer as? CarInfoObserver else {
                    return
                }

                observer.carInfoPropertyChanged(self, property: property)
            }
        }
    }

}
