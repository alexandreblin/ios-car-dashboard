//
//  CarDoors.swift
//  CarDash
//
//  Created by Alexandre Blin on 12/06/2016.
//  Copyright © 2016 Alexandre Blin. All rights reserved.
//

import UIKit

/// Represents which doors are open
struct CarDoors: OptionSet {
    let rawValue: Int

    static let None       = CarDoors(rawValue: 0)
    static let FrontLeft  = CarDoors(rawValue: 1 << 0)
    static let FrontRight = CarDoors(rawValue: 1 << 2)
    static let RearLeft   = CarDoors(rawValue: 1 << 3)
    static let RearRight  = CarDoors(rawValue: 1 << 4)
    static let Trunk      = CarDoors(rawValue: 1 << 5)
    static let Hood       = CarDoors(rawValue: 1 << 6)
    static let FuelFlap   = CarDoors(rawValue: 1 << 7)

    /// Makes a visual representation of the car doors state
    ///
    /// - Returns: A UIImage representing the open car doors
    func imageRepresentation() -> UIImage? {
        guard let base = UIImage(named: "cardoors_base") else {
            return nil
        }

        UIGraphicsBeginImageContextWithOptions(base.size, false, UIScreen.main.scale)

        base.draw(at: CGPoint.zero)

        var imagesToDraw: [String] = []

        if self.contains(.FrontLeft) {
            imagesToDraw.append("cardoors_frontleft")
        }

        if self.contains(.FrontRight) {
            imagesToDraw.append("cardoors_frontright")
        }

        if self.contains(.RearLeft) {
            imagesToDraw.append("cardoors_rearleft")
        }

        if self.contains(.RearRight) {
            imagesToDraw.append("cardoors_rearright")
        }

        if self.contains(.Trunk) {
            imagesToDraw.append("cardoors_trunk")
        }

        if self.contains(.Hood) {
            imagesToDraw.append("cardoors_hood")
        }

        if self.contains(.FuelFlap) {
            imagesToDraw.append("cardoors_fuelflap")
        }

        for image in imagesToDraw {
            UIImage(named: image)?.draw(at: CGPoint.zero)
        }

        let result = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return result
    }

    /// Make a string representation of the car doors state,
    /// e.g. "front left door open"
    ///
    /// - Returns: The car door state in French
    func stringRepresentation() -> String {
        var doorStrings: [String] = []

        var mainDoorsOpen = 0

        for door in [CarDoors.FrontLeft, CarDoors.FrontRight, CarDoors.RearLeft, CarDoors.RearRight] {
            if self.contains(door) {
                mainDoorsOpen += 1
            }
        }

        if mainDoorsOpen >= 2 {
            // if more than one "main" door is open, don't specify which one
            doorStrings.append("portières")
        } else if mainDoorsOpen == 1 {
            if self.contains(.FrontLeft) {
                doorStrings.append("portière avant gauche")
            }

            if self.contains(.FrontRight) {
                doorStrings.append("portière avant droite")
            }

            if self.contains(.RearLeft) {
                doorStrings.append("portière arrière gauche")
            }

            if self.contains(.RearRight) {
                doorStrings.append("portière arrière droite")
            }
        }

        if self.contains(.Trunk) {
            doorStrings.append("coffre")
        }

        if self.contains(.Hood) {
            doorStrings.append("capot")
        }

        if self.contains(.FuelFlap) {
            doorStrings.append("trappe réservoir")
        }

        // French is hard
        var suffix = " ouvert"

        if !self.contains(.Trunk) && !self.contains(.Hood) {
            suffix += "e"
        }

        if doorStrings.count >= 2 || mainDoorsOpen >= 2 {
            suffix += "s"
        }

        if doorStrings.count >= 2 {
            let last2 = doorStrings.removeLast()
            let last1 = doorStrings.removeLast()

            doorStrings.append("\(last1) et \(last2)")
        }

        let result = doorStrings.joined(separator: ", ") + suffix

        return String(result.characters.prefix(1)).uppercased() + String(result.characters.dropFirst())
    }
}
