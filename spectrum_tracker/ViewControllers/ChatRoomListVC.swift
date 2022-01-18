//
//  ChatRoomListVC.swift
//  spectrum_tracker
//
//  Created by Alex Chang on 2020/9/23.
//  Copyright © 2020 JO. All rights reserved.
//

import UIKit
import TwilioChatClient
import Alamofire
import SwiftyJSON
import SwiftyUserDefaults


class ChatRoomListVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var channels: [TCHChannel] = []
    var partners: [TrackerModel?] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        initData()
        initUI()
    }
    
    func initUI() {
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func initData() {
        partners.removeAll()
        channels.removeAll()
        for channel in ChannelManager.sharedManager.privateChannels {
            let channelName = channel.uniqueName ?? ""
            let partnerId = ChannelManager.getPartnerId(from: channelName)
            
            if partnerId == "" {
                continue
            }
            if channel.member(withIdentity: partnerId) == nil {
                continue
            }
            
            channels.append(channel)
            var tracker: TrackerModel? = nil
            for _tracker in Global.shared.AllTrackerList {
                if _tracker.spectrumId == partnerId {
                    tracker = _tracker
                    break
                }
            }
            
            partners.append(tracker)
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        MainContainerViewController.instance.hideOverlay()
    }
    
    @IBAction func onInviteButton(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatInviteDialogVC") as! ChatInviteDialogVC
        vc.modalPresentationStyle = .overCurrentContext
        vc.inviteHandler = { email in
            self.inviteToChat(email: email)
        }
        self.present(vc, animated: false)
    }
    @IBAction func inviteButtonTappe(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatInviteDialogVC") as! ChatInviteDialogVC
        vc.modalPresentationStyle = .overCurrentContext
        vc.inviteHandler = { email in
            self.inviteToChat(email: email)
        }
        self.present(vc, animated: false)
    }
    
    func updateList() {
        initData()
        tableView.reloadData()
    }
    
    func inviteToChat(email: String) {
        let channelName = ChannelManager.sharedManager.getChannelName(partnerId: email)
        
        let reqInfo = URLManager.inviteJoinChat()
        let parameters: Parameters = ["email": email]
        let headers: HTTPHeaders = ["X-CSRFToken": Global.shared.csrfToken]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)

        request.responseString { dataResponse in
            ChannelManager.sharedManager.joinOrCreatePrivateChannelWith(name: channelName, partnerId: email)
            self.view.makeToast("Successfully invited to join chat".localized())
            
//            if(dataResponse.response == nil || dataResponse.value == nil) {
//                self.view.makeToast("Weak cell phone signal is detected")
//                return
//            }
//            //print(dataResponse)
//            let code = dataResponse.response!.statusCode
//            let json = JSON.init(parseJSON: dataResponse.value!)
//
//            if(code == 200) {
//
//            } else {
//                let error = ErrorModel.parseJSON(json)
//                self.view.makeToast(error.message)
//            }
        }
    }
}

extension ChatRoomListVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatRoomListCell", for: indexPath) as! ChatRoomListCell
        
        if indexPath.row < channels.count {
            cell.setupCell(channel: channels[indexPath.row], tracker: partners[indexPath.row], indexPath: indexPath)
        }
        
        cell.acceptHandler = {
            self.gotoChatRoom(channelName: self.channels[indexPath.row].uniqueName ?? "")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < channels.count else { return }
        
        self.gotoChatRoom(channelName: channels[indexPath.row].uniqueName ?? "")
    }
    
    func gotoChatRoom(channelName: String) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatRoomVC") as! ChatRoomVC
        vc.channelName = channelName
        MainContainerViewController.instance.setPage(controller: vc)
    }
}
