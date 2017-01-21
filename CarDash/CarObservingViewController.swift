//
//  CarObservingViewController.swift
//  CarDash
//
//  Created by Alexandre Blin on 12/06/2016.
//  Copyright © 2016 Alexandre Blin. All rights reserved.
//

import UIKit

class CarObservingViewController: UIViewController, CarInfoObserver {
    let carInfo = CarInfo.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        carInfo.addObserver(self)
    }

    func carInfoPropertyChanged(_ carInfo: CarInfo, property: CarInfo.Property) {
    }
}
