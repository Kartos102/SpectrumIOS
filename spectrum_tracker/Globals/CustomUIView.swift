//
//  CustomUIView.swift
//  spectrum_tracker
//
//  Created by test on 1/14/22.
//  Copyright © 2022 JO. All rights reserved.
//

import UIKit
@IBDesignable
class CustomUIView: UIView {
    @IBInspectable var scale: Float = 1.0
    func setup() {
        let border = CALayer()
        let width = CGFloat(2.0)
        border.borderColor = UIColor.darkGray.cgColor
        border.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width * CGFloat(self.scale) , height: self.frame.size.height)
        border.borderWidth = width
        border.cornerRadius = 5
        self.layer.addSublayer(border)
        self.layer.masksToBounds = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
//        setup()
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        setup()
    }
    override func layoutSubviews() {
        setup()
    }
}
