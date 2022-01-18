//
//  ChatRoomListCell.swift
//  spectrum_tracker
//
//  Created by Alex Chang on 2020/9/23.
//  Copyright © 2020 JO. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import TwilioChatClient

class ChatRoomListCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var unreadCountLabel: UILabel!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    var channel: TCHChannel!
    var tracker: TrackerModel? = nil
    var indexPath: IndexPath!
    
    var acceptHandler: (() -> ())? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupCell(channel: TCHChannel, tracker: TrackerModel?, indexPath: IndexPath) {
        self.channel = channel
        self.tracker = tracker
        self.indexPath = indexPath
        
        if let _tracker = tracker {
            if let imageUrl = Global.shared.driverPhotos[_tracker._id], imageUrl != "" {
                let url = URL(string: imageUrl)
                self.profileImageView.load(url!)
            } else {
                getImageUrl("driver_" + _tracker.assetId + ".jpg", trackerId: _tracker._id)
            }
            
            userNameLabel.text = _tracker.driverName
        } else {
            userNameLabel.text = ChannelManager.getPartnerId(from: channel.uniqueName ?? "")
        }
        
        profileImageView.layer.cornerRadius = 20
        profileImageView.layer.borderColor = UIColor.red.cgColor
        profileImageView.layer.borderWidth = 1
        
        unreadCountLabel.layer.cornerRadius = 10
        acceptButton.layer.cornerRadius = 5
        rejectButton.layer.cornerRadius = 5
        
        if channel.status == .invited {
            unreadCountLabel.isHidden = true
            acceptButton.isHidden = false
            rejectButton.isHidden = false
            
            userNameLabel.text = ChannelManager.getPartnerId(from: channel.uniqueName ?? "") + " " + "invited you to the chat".localized()
        } else {
            acceptButton.isHidden = true
            rejectButton.isHidden = true
            
            let channelName = channel.uniqueName ?? ""
            if let unreadCount = ChannelManager.sharedManager.unreadCountMap[channelName],
                unreadCount > 0 {
                unreadCountLabel.isHidden = false
                unreadCountLabel.text = "\(unreadCount)"
            } else {
                unreadCountLabel.isHidden = true
            }
        }
    }

    func getImageUrl(_ fileName: String, trackerId: String){
        
        let reqInfo = URLManager.getImageUrl()
        
        let parameters: Parameters = [
            "name" : fileName
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: JSONEncoding.default , headers: headers)
        request.responseString {
            dataResponse in
            
            if(dataResponse.data == nil || dataResponse.value == nil) {
                return
            }
            let json = JSON.init(parseJSON: dataResponse.value!)
            if(json["success"].boolValue) {
                let imageUrl = json["url"].stringValue
                Global.shared.driverPhotos[trackerId] = imageUrl
                
                let url = URL(string: imageUrl)
                self.profileImageView.load(url!)
            }
            else {
                self.profileImageView.image = UIImage(named: "driver_empty")
            }
        }
    }
    
    @IBAction func acceptButtonTapped(_ sender: Any) {
        channel.join { _ in
            self.acceptHandler?()
        }
    }
    
    @IBAction func rejectButtonTapped(_ sender: Any) {
        channel.declineInvitation { _ in
            
        }
    }
}
