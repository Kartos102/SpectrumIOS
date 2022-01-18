import UIKit
import TwilioChatClient

protocol ChannelManagerDelegate {
    func didGetPrivateChannelList()
    func didGetPublicChannelList()
}

class ChannelManager: NSObject {
    static let sharedManager = ChannelManager()
    
    static let defaultChannelUniqueName = "general"
    static let defaultChannelName = "General Channel"
    
    var delegate:ChannelManagerDelegate?
    
    var channelsList:TCHChannels?
    var generalChannel:TCHChannel!
    
    var privateChannels: [TCHChannel] = []
    var publicChannels: [TCHChannel] = []
    
    var unreadCountMap: [String: Int] = [:]
    
    override init() {
        super.init()
        
    }
    
    // MARK: - Populate channel Descriptors
    
    func extractChannelDescriptors(descriptors: [TCHChannelDescriptor], completion: (([TCHChannel]) -> ())? = nil) {
        var channelDescriptors = descriptors
        var channels: [TCHChannel] = []
        
        DispatchQueue.global().async {
            while channelDescriptors.count > 0 {
                let descriptor = channelDescriptors.first!
                
                var isFinish = false
                
                descriptor.channel { (result, channel) in
                    if let _channel = channel {
                        channels.append(_channel)
                    }
                    channelDescriptors.removeFirst()
                    isFinish = true
                }
                
                while !isFinish {
                    Thread.sleep(forTimeInterval: 0.2)
                }
            }
            
            DispatchQueue.main.async {
                completion?(channels)
            }
        }
    }
    
    func populateUserChannelDescriptors(completion: (() -> ())? = nil) {
        channelsList?.userChannelDescriptors { result, paginator in
            guard let paginator = paginator else { return }

            self.extractChannelDescriptors(descriptors: paginator.items()) { channels in
                self.privateChannels = channels
                completion?()
            }
        }
    }
    
    func populatePublicChannelDescriptors(completion: (() -> ())? = nil) {
        channelsList?.publicChannelDescriptors { result, paginator in
            guard let paginator = paginator else { return }

            self.extractChannelDescriptors(descriptors: paginator.items()) { channels in
                self.publicChannels = channels
                completion?()
            }
        }
    }
    
    func getChannelName(partnerId: String) -> String {
        let myId = Global.shared.username!
        
        if myId < partnerId {
            return "\(myId)__\(partnerId)"
        } else {
            return "\(partnerId)__\(myId)"
        }
    }
    
    static func getPartnerId(from channelName: String) -> String {
        let userIds = channelName.components(separatedBy: "__")
        let myId = Global.shared.username!
        
        guard userIds.count >= 2 else { return "" }
        
        if userIds[0] == myId {
            return userIds[1]
        } else {
            return userIds[0]
        }
    }
    
    // MARK: - Private channel
    
    func joinOrCreatePrivateChannelWith(name: String, partnerId: String, completion: ((Bool) -> ())? = nil) {
        if let _ = self.getPrivateChannelBy(name: name) {
            self.joinPrivateChannelWith(name: name, partnerId: partnerId, completion: completion)
        } else {
            self.createPrivateChannelWith(name: name) { result in
                if result {
                    self.joinPrivateChannelWith(name: name, partnerId: partnerId, completion: completion)
                }
            }
        }
    }
    
    func joinPrivateChannelWith(name: String, partnerId: String, completion: ((Bool) -> ())? = nil) {
        guard let channel = self.getPrivateChannelBy(name: name) else {
            completion?(false)
            return
        }
        
        if channel.status == .joined {
            channel.members?.invite(byIdentity: partnerId, completion: nil)
            self.getUnreadCount(channel: channel)
            completion?(true)
            return
        }
        
        channel.join { result in
            channel.members?.invite(byIdentity: partnerId, completion: nil)
            self.getUnreadCount(channel: channel)
            completion?(result.isSuccessful())
        }
    }
    
    func createPrivateChannelWith(name: String, completion: ((Bool) -> ())? = nil) {
        if let _ = self.getPrivateChannelBy(name: name) {
            completion?(true)
            return
        }
        
        let channelOptions = [
            TCHChannelOptionFriendlyName: name,
            TCHChannelOptionUniqueName: name,
            TCHChannelOptionType: TCHChannelType.private.rawValue
        ] as [String : Any]

        self.channelsList?.createChannel(options: channelOptions, completion: { (result, channel) in
            if let _channel = channel {
                self.privateChannels.append(_channel)
                completion?(true)
            } else {
                completion?(result.isSuccessful())
            }
        })
    }
    
    func getPrivateChannelBy(name: String) -> TCHChannel? {
        for channel in self.privateChannels {
            if channel.uniqueName == name {
                return channel
            }
        }
        
        return nil
    }
    
    // MARK: - Public channel
    
    func joinOrCreatePublicChannelWith(name: String, partnerId: String, completion: ((Bool) -> ())? = nil) {
        if let _ = self.getPublicChannelBy(name: name) {
            self.joinPublicChannelWith(name: name, partnerId: partnerId, completion: completion)
        } else {
            self.createPublicChannelWith(name: name) { result in
                if result {
                    self.joinPublicChannelWith(name: name, partnerId: partnerId, completion: completion)
                }
            }
        }
    }
    
    func joinPublicChannelWith(name: String, partnerId: String, completion: ((Bool) -> ())? = nil) {
        guard let channel = self.getPublicChannelBy(name: name) else {
            completion?(false)
            return
        }
        
        if channel.status == .joined {
            channel.members?.invite(byIdentity: partnerId, completion: nil)
            completion?(true)
            return
        }
        
        channel.join { result in
            channel.members?.invite(byIdentity: partnerId, completion: nil)
            completion?(result.isSuccessful())
        }
    }
    
    func createPublicChannelWith(name: String, completion: ((Bool) -> ())? = nil) {
        if let _ = self.getPublicChannelBy(name: name) {
            completion?(true)
            return
        }
        
        let channelOptions = [
            TCHChannelOptionFriendlyName: name,
            TCHChannelOptionUniqueName: name,
            TCHChannelOptionType: TCHChannelType.public.rawValue
        ] as [String : Any]

        self.channelsList?.createChannel(options: channelOptions, completion: { (result, channel) in
            if let _channel = channel {
                self.publicChannels.append(_channel)
                completion?(true)
            } else {
                completion?(result.isSuccessful())
            }
        })
    }
    
    func getPublicChannelBy(name: String) -> TCHChannel? {
        for channel in self.publicChannels {
            if channel.uniqueName == name {
                return channel
            }
        }
        
        return nil
    }
    
    func getUnreadCount(channel: TCHChannel) {
        channel.getUnconsumedMessagesCount { result, count in
            if result.isSuccessful() {
                self.unreadCountMap[channel.uniqueName ?? ""] = Int(count)
                
                if MainContainerViewController.instance != nil {
                    MainContainerViewController.instance.onUpdatedUnreadCount()
                }
            } else {
                channel.getMessagesCount { result, count in
                    if result.isSuccessful() {
                        self.unreadCountMap[channel.uniqueName ?? ""] = Int(count)
                    } else {
                        self.unreadCountMap[channel.uniqueName ?? ""] = 0
                    }
                    if MainContainerViewController.instance != nil {
                        MainContainerViewController.instance.onUpdatedUnreadCount()
                    }
                }
            }
        }
    }
}

// MARK: - TwilioChatClientDelegate
extension ChannelManager : TwilioChatClientDelegate {
    func chatClient(_ client: TwilioChatClient, channelAdded channel: TCHChannel) {
        if channel.status == .joined || channel.status == .invited {
            privateChannels.append(channel)
        }
        MainContainerViewController.instance.checkChatInvitation()
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, updated: TCHChannelUpdate) {
        self.getUnreadCount(channel: channel)
        
        if let index = privateChannels.firstIndex(where: { $0.uniqueName == channel.uniqueName }), index >= 0 {
            if channel.status == .joined || channel.status == .invited {
                privateChannels[index] = channel
            } else {
                privateChannels.remove(at: index)
            }
        }
        
        MainContainerViewController.instance.checkChatInvitation()
    }
    
    func chatClient(_ client: TwilioChatClient, channelDeleted channel: TCHChannel) {
        if let index = privateChannels.firstIndex(where: { $0.uniqueName == channel.uniqueName }), index >= 0 {
            privateChannels.remove(at: index)
        }
        
        MainContainerViewController.instance.checkChatInvitation()
    }
    
    func chatClient(_ client: TwilioChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        if status == .completed {
            self.populateUserChannelDescriptors {
                self.delegate?.didGetPrivateChannelList()
            }
            
            self.populatePublicChannelDescriptors {
                self.delegate?.didGetPublicChannelList()
            }
        }
    }
}
