//
//  TripInfoView.swift
//  CarDash
//
//  Created by Alexandre Blin on 14/01/2017.
//  Copyright © 2017 Alexandre Blin. All rights reserved.
//

import UIKit

/// View containing 3 icons and values to display trip computer data.
/// Two modes are available: instant view and trip view (which determines
/// which icons to display above the values)
class TripInfoView: UIView {
    enum Mode {
        case instant
        case trip
    }

    @IBOutlet weak var label1: UILabel?
    @IBOutlet weak var label2: UILabel?
    @IBOutlet weak var label3: UILabel?

    @IBOutlet private weak var titleLabel: UILabel?

    @IBOutlet private weak var image1: UIImageView?
    @IBOutlet private weak var image2: UIImageView?
    @IBOutlet private weak var image3: UIImageView?

    static func view(withTitle title: String, mode: Mode) -> TripInfoView {
        guard let view = Bundle.main.loadNibNamed("TripInfoView", owner: nil, options: nil)?.first as? TripInfoView else {
            fatalError("Could not load TripInfoView from nib")
        }

        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        view.titleLabel?.text = title

        switch mode {
        case .instant:
            view.image1?.image = UIImage(named: "icon_gasstation")
            view.image2?.image = UIImage(named: "icon_fuel")
            view.image3?.image = UIImage(named: "icon_temperature")
        case .trip:
            view.image1?.image = UIImage(named: "icon_distance")
            view.image2?.image = UIImage(named: "icon_fuel")
            view.image3?.image = UIImage(named: "icon_speed")
        }

        return view
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = UIColor.clear
    }
}
