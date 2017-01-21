//
//  DashboardViewController.swift
//  CarDash
//
//  Created by Alexandre Blin on 12/06/2016.
//  Copyright © 2016 Alexandre Blin. All rights reserved.
//

import UIKit

/// Main view controller displayed on the external screen.
///
/// Contains a view controller on the left which depends on
/// what audio source is currently selected (FM, Bluetooth or Aux)
///
/// Also contains trip info view controller on the right displaying
/// trip computer data and a live fuel usage graph.
///
/// Displays the current time and outside temperature at the top.
class DashboardViewController: CarObservingViewController {
    /// Main container view. Has a fixed size of 1280x720 and is then scaled
    /// to the external screen resolution.
    @IBOutlet private weak var dashboardView: UIView!

    /// Current audio source label
    @IBOutlet private weak var modeLabel: UILabel!

    @IBOutlet private weak var hoursLabel: UILabel!
    @IBOutlet private weak var minutesLabel: UILabel!
    @IBOutlet private weak var timeColonLabel: UILabel!

    @IBOutlet private weak var temperatureLabel: UILabel!

    private var popupView: PopupView! = nil
    private var audioSettingsView: AudioSettingsView! = nil

    private var subViewControllers: [CarInfo.CarRadioSource: UIViewController] = [:]
    private weak var displayedViewController: UIViewController? = nil
    @IBOutlet private weak var mainContainerView: UIView!

    private var volumePopupTimer: Timer? = nil

    // TODO: move this in a subclass
    @IBOutlet private weak var volumeContainerView: UIView!
    @IBOutlet private weak var volumePopup: UIView!
    @IBOutlet private weak var volumeLabel: UILabel!
    @IBOutlet private weak var volumeBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var volumePopupYConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup child view controllers
        if let viewController = storyboard?.instantiateViewController(withIdentifier: "radioViewController") {
            subViewControllers[.fmTuner] = viewController
        }

        if let viewController = storyboard?.instantiateViewController(withIdentifier: "bluetoothViewController") {
            subViewControllers[.phone] = viewController
        }

        if let viewController = storyboard?.instantiateViewController(withIdentifier: "jackViewController") {
            subViewControllers[.aux] = viewController
        }

        for viewController in subViewControllers.values {
            viewController.view.backgroundColor = UIColor.clear
        }

        switchToSource(.fmTuner)

        // Prepare popup view to display messages and audio settings view (hidden by default)

        popupView = Bundle.main.loadNibNamed("PopupView", owner: nil, options: nil)?.first as? PopupView
        popupView.isHidden = true
        popupView.addToView(dashboardView)

        audioSettingsView = Bundle.main.loadNibNamed("AudioSettingsView", owner: nil, options: nil)?.first as? AudioSettingsView
        audioSettingsView.isHidden = true
        audioSettingsView.addToView(dashboardView)

        // Setup time and temperature labels

        updateTime()
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(DashboardViewController.updateTime), userInfo: nil, repeats: true)

        updateTemperature()
        Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(DashboardViewController.updateTemperature), userInfo: nil, repeats: true)

        volumePopupYConstraint.constant = -400
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Scale the view to the external screen's bounds. This makes sure the view is always
        // displayed the same way on any screen resolution. This could be removed since the 
        // external screen I'm now using has a fixed resolution and is unlikely to change.
        dashboardView.transform = CGAffineTransform(scaleX: view.bounds.width / dashboardView.bounds.width, y: view.bounds.height / dashboardView.bounds.height)
    }

    private func switchToSource(_ source: CarInfo.CarRadioSource) {
        guard let newViewController = subViewControllers[source] else {
            return
        }

        // Fade the new subViewController into view

        addChildViewController(newViewController)
        mainContainerView.addSubview(newViewController.view)
        newViewController.view.frame = mainContainerView.bounds

        displayedViewController?.willMove(toParentViewController: nil)

        newViewController.view.alpha = 0
        UIView.animate(withDuration: 0.2, animations: {
            newViewController.view.alpha = 1
            self.displayedViewController?.view.alpha = 0

            switch source {
            case .fmTuner:
                self.modeLabel.text = "Radio FM"
            case .phone:
                self.modeLabel.text = "Auxiliaire 1"
            case .aux:
                self.modeLabel.text = "Auxiliaire 2"
            }
        }, completion: { _ in
            self.displayedViewController?.view.removeFromSuperview()
            self.displayedViewController?.removeFromParentViewController()
            newViewController.didMove(toParentViewController: self)
            self.displayedViewController = newViewController
        })
    }

    override func carInfoPropertyChanged(_ carInfo: CarInfo, property: CarInfo.Property) {
        // Update view when data changes on the CAN bus
        if property == .radioSource {
            switchToSource(carInfo.radioSource)
        } else if property == .infoMessage {
            if let message = carInfo.infoMessage {
                // Show message
                popupView.textLabel.text = message
                popupView.setImage(nil)

                if popupView.isHidden {
                    popupView.alpha = 0
                    popupView.isHidden = false

                    UIView.animate(withDuration: 0.2, animations: {
                        self.popupView.alpha = 1
                    })
                }
            } else {
                // Hide message
                UIView.animate(withDuration: 0.2, animations: {
                    self.popupView.alpha = 0
                }, completion: { _ in
                    self.popupView.isHidden = true
                })
            }
        } else if property == .carDoors {
            if carInfo.carDoors != .None {
                // Display car doors status if at least one door is open
                popupView.textLabel.text = carInfo.carDoors.stringRepresentation()
                popupView.setImage(carInfo.carDoors.imageRepresentation())

                if popupView.isHidden {
                    popupView.alpha = 0
                    popupView.isHidden = false

                    UIView.animate(withDuration: 0.2, animations: {
                        self.popupView.alpha = 1
                    })
                }
            } else {
                // Hide car doors status
                UIView.animate(withDuration: 0.2, animations: {
                    self.popupView.alpha = 0
                    }, completion: { _ in
                        self.popupView.isHidden = true
                })
            }
        } else if property == .audioSettings {
            if carInfo.audioSettings.activeMode != .none {
                // Display audio settings
                audioSettingsView.audioSettings = carInfo.audioSettings

                if audioSettingsView.isHidden {
                    audioSettingsView.alpha = 0
                    audioSettingsView.isHidden = false

                    UIView.animate(withDuration: 0.2, animations: {
                        self.audioSettingsView.alpha = 1
                    })
                }
            } else {
                // Hide audio settings
                if !audioSettingsView.isHidden {
                    UIView.animate(withDuration: 0.2, animations: {
                        self.audioSettingsView.alpha = 0
                        }, completion: { _ in
                            self.audioSettingsView.isHidden = true
                    })
                }
            }
        } else if property == .volume {
            // Animate volume bar into view
            displayVolumeBar()

            UIView.animate(withDuration: 0.2, animations: {
                self.volumeBarWidthConstraint.constant = CGFloat(self.carInfo.volume) * (self.volumeContainerView.bounds.width / 30.0)
                self.volumePopup.layoutIfNeeded()
            })

            volumeLabel.text = "\(carInfo.volume)"
        }
    }

    /// Displays the volume bar and hides it after 500ms of inactivity
    private func displayVolumeBar() {
        volumePopupTimer?.invalidate()
        volumePopupTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(DashboardViewController.hideVolumeBar), userInfo: nil, repeats: false)

        if !volumePopup.isHidden {
            return
        }

        volumePopup.isHidden = false

        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .beginFromCurrentState, animations: {
            self.volumePopupYConstraint.constant = -275
            self.volumePopup.layoutIfNeeded()
        }) { _ in }
    }

    func hideVolumeBar() {
        if volumePopup.isHidden {
            return
        }

        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .beginFromCurrentState, animations: {
            self.volumePopupYConstraint.constant = -400
            self.volumePopup.layoutIfNeeded()
        }) { _ in
            self.volumePopup.isHidden = true
        }
    }

    func updateTime() {
        UIView.animate(withDuration: 0.2, animations: {
            self.timeColonLabel.alpha = self.timeColonLabel.alpha > 0 ? 0 : 1
        })

        let dateComponents = (Calendar.current as NSCalendar).components([.hour, .minute], from: Date())

        guard let hour = dateComponents.hour, let minute = dateComponents.minute else {
            return
        }

        hoursLabel.text = "\(hour)"
        minutesLabel.text = String(format: "%02ld", minute)
    }

    func updateTemperature() {
        temperatureLabel.text = "\(carInfo.temperature)º"
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
