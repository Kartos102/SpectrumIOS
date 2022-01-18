import UIKit
import TwilioChatClient

class MessagingManager: NSObject {
    
    static let shared = MessagingManager()
    
    var client:TwilioChatClient?
    var delegate:ChannelManager?
    var connected = false
    
    var userIdentity:String {
        return Global.shared.username
    }
    
    override init() {
        super.init()
        delegate = ChannelManager.sharedManager
    }
    
    // MARK: User and session management
    
    func loginWithUsername(username: String, completion: @escaping (Bool, NSError?) -> Void) {
        connectClientWithCompletion(completion: completion)
    }
    
    func logout() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.client?.shutdown()
            self.client = nil
        }
        self.connected = false
    }
    
    // MARK: Twilio Client
    
    func connectClientWithCompletion(completion: @escaping (Bool, NSError?) -> Void) {
        if (client != nil) {
            logout()
        }
        
        requestTokenWithCompletion { succeeded, token in
            if let token = token, succeeded {
                self.initializeClientWithToken(token: token)
                completion(succeeded, nil)
            }
            else {
                let error = self.errorWithDescription(description: "Could not get access token", code:301)
                completion(succeeded, error)
            }
        }
    }
    
    func initializeClientWithToken(token: String) {
        TwilioChatClient.chatClient(withToken: token, properties: nil, delegate: self) { [weak self] result, chatClient in
            guard (result.isSuccessful()) else { return }
            
            self?.connected = true
            self?.client = chatClient
        }
    }
    
    func requestTokenWithCompletion(completion:@escaping (Bool, String?) -> Void) {
        if let device = UIDevice.current.identifierForVendor?.uuidString {
            
            TokenRequestHandler.fetchToken(params: ["device": device, "identity": self.userIdentity]) {response,error in
                var token: String?
                token = response["token"] as? String
                completion(token != nil, token)
            }
        }
    }
    
    func errorWithDescription(description: String, code: Int) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : description]
        return NSError(domain: "app", code: code, userInfo: userInfo)
    }
}

// MARK: - TwilioChatClientDelegate
extension MessagingManager : TwilioChatClientDelegate {
    func chatClient(_ client: TwilioChatClient, channelAdded channel: TCHChannel) {
        self.delegate?.chatClient(client, channelAdded: channel)
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, updated: TCHChannelUpdate) {
        self.delegate?.chatClient(client, channel: channel, updated: updated)
    }
    
    func chatClient(_ client: TwilioChatClient, channelDeleted channel: TCHChannel) {
        self.delegate?.chatClient(client, channelDeleted: channel)
    }
    
    func chatClient(_ client: TwilioChatClient, notificationInvitedToChannelWithSid channelSid: String) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, memberJoined member: TCHMember) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        if status == TCHClientSynchronizationStatus.completed {
            ChannelManager.sharedManager.channelsList = client.channelsList()
        }
        self.delegate?.chatClient(client, synchronizationStatusUpdated: status)
    }
    
    func chatClientTokenWillExpire(_ client: TwilioChatClient) {
        requestTokenWithCompletion { succeeded, token in
            if (succeeded) {
                client.updateToken(token!)
            }
            else {
                print("Error while trying to get new access token")
            }
        }
    }
    
    func chatClientTokenExpired(_ client: TwilioChatClient) {
        requestTokenWithCompletion { succeeded, token in
            if (succeeded) {
                client.updateToken(token!)
            }
            else {
                print("Error while trying to get new access token")
            }
        }
    }
}
