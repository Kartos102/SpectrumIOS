//
//  ChatRoomVC.swift
//  spectrum_tracker
//
//  Created by Alex Chang on 2020/9/22.
//  Copyright © 2020 JO. All rights reserved.
//

import UIKit
import TwilioChatClient
import SwiftyJSON
import Alamofire

class ChatRoomVC: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageSendContainerView: UIView!
    @IBOutlet weak var bSend: UIButton!
    @IBOutlet weak var messageGrowTextView: GrowingTextView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var tracker: TrackerModel? = nil
    var isFromChatRoomList =  false
    var channelName: String = ""
    var channel: TCHChannel? = nil
    var messages: TCHMessages? = nil
    var messageList: [TCHMessage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        initChatRoom()
        initUI()
    }
    
    func initUI() {
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.cornerRadius = 16
        
        messageSendContainerView.layer.borderColor = UIColor.lightGray.cgColor
        messageSendContainerView.layer.borderWidth = 1
        messageSendContainerView.layer.cornerRadius = 24
        
        tableView.dataSource = self
        tableView.delegate = self
        
        if let _tracker = self.tracker {
            if let imageUrl = Global.shared.driverPhotos[_tracker._id], imageUrl != "" {
                let url = URL(string: imageUrl)
                self.profileImageView.load(url!)
            } else {
                getImageUrl("driver_" + _tracker.assetId + ".jpg", trackerId: _tracker._id)
            }
            self.userNameLabel.text = _tracker.driverName
        }
    }
    
    func initChatRoom() {
        self.channel = ChannelManager.sharedManager.getPrivateChannelBy(name: channelName)
        
        let partnerId = ChannelManager.getPartnerId(from: channelName)
        for _tracker in Global.shared.AllTrackerList {
            if _tracker.spectrumId == partnerId {
                self.tracker = _tracker
                break
            }
        }
        
        if self.tracker == nil {
            self.tracker = TrackerModel()
            self.tracker?.spectrumId = partnerId
            self.tracker?.driverName = partnerId
        }
        
        self.initChannel()
    }
    
    func initChannel() {
        guard let channel = self.channel else { return }
        
        channel.delegate = self
        if channel.status == .joined {
            loadMessages()
        } else {
            channel.join { result in
                if result.isSuccessful() {
                    self.loadMessages()
                }
            }
        }
    }
    
    func loadMessages() {
        self.messages = self.channel?.messages
        self.channel?.getMessagesCount(completion: { result, count in
            guard result.isSuccessful() else { return }
            self.messages?.getLastWithCount(count, completion: { (result, messages) in
                guard result.isSuccessful() else { return }
                self.messageList = messages ?? []
                self.tableView.reloadData()
                self.scrollToBottom()
            })
            
            self.messages?.setAllMessagesConsumedWithCompletion(nil)
            if let channelName = self.channel?.uniqueName {
                ChannelManager.sharedManager.unreadCountMap[channelName] = 0
            }
        })
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        if isFromChatRoomList {
            _ = self.navigationController?.popViewController(animated: true)
        } else {
            MainContainerViewController.instance.hideOverlay()
        }
    }
    
    @IBAction func bSend(_ sender: Any) {
        guard let message = messageGrowTextView.text, message != "" else { return }
        
        let messageOption = TCHMessageOptions().withBody(message)
        self.messages?.sendMessage(with: messageOption, completion: { (result, message) in
            print(result.isSuccessful())
        })
        
        messageGrowTextView.text = ""
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
            } else {
                self.profileImageView.image = UIImage(named: "driver_empty")
            }
        }
    }
    
    func scrollToBottom() {
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.messageList.count-1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
}

extension ChatRoomVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < messageList.count {
            let message = messageList[indexPath.row]
            if message.author == self.tracker?.spectrumId {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ChatRoomLeftCell", for: indexPath) as! ChatRoomLeftCell
                cell.partnerName = self.tracker?.driverName ?? ""
                cell.setupCell(message: message, indexPath: indexPath)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ChatRoomRightCell", for: indexPath) as! ChatRoomRightCell
                cell.setupCell(message: message, indexPath: indexPath)
                return cell
                
            }
        } else {
            return UITableViewCell()
        }
    }
}

extension ChatRoomVC: TCHChannelDelegate {
    func chatClient(_ client: TwilioChatClient, channelDeleted channel: TCHChannel) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, updated: TCHChannelUpdate) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, memberLeft member: TCHMember) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, memberJoined member: TCHMember) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, typingEndedOn channel: TCHChannel, member: TCHMember) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, messageAdded message: TCHMessage) {
        messageList.append(message)
        self.messages?.setAllMessagesConsumedWithCompletion(nil)
        self.tableView.reloadData()
        self.scrollToBottom()
    }
    
    func chatClient(_ client: TwilioChatClient, typingStartedOn channel: TCHChannel, member: TCHMember) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, messageDeleted message: TCHMessage) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, member: TCHMember, updated: TCHMemberUpdate) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, message: TCHMessage, updated: TCHMessageUpdate) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, member: TCHMember, userSubscribed user: TCHUser) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, member: TCHMember, userUnsubscribed user: TCHUser) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, member: TCHMember, user: TCHUser, updated: TCHUserUpdate) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, synchronizationStatusUpdated status: TCHChannelSynchronizationStatus) {
        
    }
}
