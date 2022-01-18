//
//  RadiusUIView.swift
//  spectrum_tracker
//
//  Created by test on 1/15/22.
//  Copyright © 2022 JO. All rights reserved.
//

import UIKit
@IBDesignable
class RadiusUIView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        roundCorners(corners: [.topLeft, .topRight], radius: 5.0)
    }
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
}
