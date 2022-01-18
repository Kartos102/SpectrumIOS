//
//  TripLogTableViewCell.swift
//  spectrum_tracker
//
//  Created by Admin on 6/27/19.
//  Copyright © 2019 JO. All rights reserved.
//

import UIKit

class TripLogTableViewCell: UITableViewCell {

    @IBOutlet var trip_icon: UIImageView!
    @IBOutlet var header: UILabel!
    @IBOutlet var range: UILabel!
    @IBOutlet var detail: UILabel!
    @IBOutlet var maxSpeed: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func update(header: String, range: String, detail: String, state: Int, maxSpeed: String) {
        self.header.text = header
        self.range.text = range
        self.detail.text = detail
        self.maxSpeed.text = "Max Speed:".localized() + " " + maxSpeed
        if (state == 0) {
            trip_icon.image = UIImage(named: "location_blue")
        }
        else {
            trip_icon.image = UIImage(named: "location_red")
        }
    }
}
