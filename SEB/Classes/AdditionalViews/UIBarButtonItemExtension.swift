//
//  UIBarButtonItemExtension.swift
//  SEB
//
//  Created by Daniel Schneider on 17.03.2025.
//

import Foundation
import UIKit

@objc extension UIBarButtonItem {
        
    convenience init(image: UIImage? = nil, style: UIBarButtonItem.Style = .plain, target: Any? = nil, action: Selector? = nil, secondaryAction: Selector? = nil) {

        let button = UIButton()
        button.setImage(image, for: .normal)

        let tapGesture = UITapGestureRecognizer(target: target, action: action)
        let longGesture = UILongPressGestureRecognizer(target: target, action: secondaryAction)
        longGesture.minimumPressDuration = 0.35 //The default duration is 0.5 seconds.

        button.addGestureRecognizer(longGesture)
        button.addGestureRecognizer(tapGesture)

        self.init(customView: button)
    }
    
    func setImage(_ selectedImage: UIImage?, tintColor: UIColor? = nil) {
        guard let button = customView as? UIButton else { return }
        button.setImage(selectedImage, for: .normal)
        button.tintColor = tintColor
        customView = button
    }
}
