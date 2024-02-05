//
//  TouchTransparentUIView.swift
//  SEB
//
//  Created by Daniel Schneider on 05.02.24.
//

import UIKit

class TouchTransparentUIView: UIView {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return true
    }
}
