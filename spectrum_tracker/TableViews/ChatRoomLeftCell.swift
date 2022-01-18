//
//  ChatRoomSenderCell.swift
//  spectrum_tracker
//
//  Created by Alex Chang on 2020/9/22.
//  Copyright © 2020 JO. All rights reserved.
//

import UIKit
import TwilioChatClient

class ChatRoomLeftCell: UITableViewCell {

    @IBOutlet weak var viewBackground: UIView!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblMessage: UILabel!
    
    var message: TCHMessage!
    var indexPath: IndexPath!
    var partnerName: String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupCell(message: TCHMessage, indexPath: IndexPath) {
        self.message = message
        self.indexPath = indexPath
        
        viewBackground.layer.cornerRadius = 8
        
        let date = message.dateUpdatedAsDate ?? Date()
        
        var dateString = date.toString("dd.MM.yyyy")
        if date.days(from: Date()) == 0 {
            dateString = "Today -"
        } else if date.days(from: Date()) == 1 {
            dateString = "Yesterday -"
        }
        
        let timeString = date.toString("hh:mm a")
        
        lblDate.text = "\(partnerName), \(dateString) \(timeString)"
        lblMessage.text = message.body
    }
}
