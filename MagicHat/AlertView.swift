//
//  AlertView.swift
//  MagicHat
//
//  Created by Jennifer Liu on 30/11/2017.
//  Copyright © 2017 Jennifer Liu. All rights reserved.
//

import Foundation
import UIKit

// MARK: AlertView

class AlertView {
    
    struct Messages {
        static let instruction = "Aim your camera at the floor and move around the room until you see the magic hat. ;)"
        static let cameraTrackingError = "Uh oh, there's something wrong with your camera. Try restarting the app."
        static let sessionFailed = "Unable to load the app. :( Please try again later."
        static let sessionInterrupted = "Uh oh, something's wrong. Try restarting the app."
    }
    
    class func showAlert(controller: UIViewController, message: String) {
        let alert = UIAlertController(title: "Please Note", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        DispatchQueue.main.async {
            controller.present(alert, animated: true, completion: nil)
        }
    }
}
