//
//  ViewController.swift
//  CarDash
//
//  Created by Alexandre Blin on 12/06/2016.
//  Copyright © 2016 Alexandre Blin. All rights reserved.
//

import UIKit

/// Debug view controller to test some animations without being
/// connected to the car's CAN bus
class DebugViewController: UIViewController {

    @IBAction func volumeDown(_ sender: AnyObject) {
        CarInfo.sharedInstance.volume -= 1
    }

    @IBAction func volumeUp(_ sender: AnyObject) {
        CarInfo.sharedInstance.volume += 1
    }

    @IBAction func switchSource(_ sender: AnyObject) {
        switch CarInfo.sharedInstance.radioSource {
        case .fmTuner:
            CarInfo.sharedInstance.radioSource = .phone
        case .phone:
            CarInfo.sharedInstance.radioSource = .aux
        case .aux:
            CarInfo.sharedInstance.radioSource = .fmTuner
        }
    }

    @IBAction func switchTripMode(_ sender: AnyObject) {
        switch CarInfo.sharedInstance.tripInfoMode {
        case .instant:
            CarInfo.sharedInstance.tripInfoMode = .trip1
        case .trip1:
            CarInfo.sharedInstance.tripInfoMode = .trip2
        case .trip2:
            CarInfo.sharedInstance.tripInfoMode = .instant
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
