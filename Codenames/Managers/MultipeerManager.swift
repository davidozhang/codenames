import MultipeerConnectivity

protocol MultipeerManagerDelegate {
    func foundPeer(peerID: MCPeerID, withDiscoveryInfo info: [String:String]?)
    func lostPeer(peerID: MCPeerID)
    func didReceiveData(data: NSData, fromPeer peerID: MCPeerID)
}

class MultipeerManager: NSObject, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate {
    static let instance = MultipeerManager()
    var delegate: MultipeerManagerDelegate?
    
    private let serviceType = "Codenames"
    private var discoveryInfo: [String: String]?
    
    private var peerID: MCPeerID?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var session: MCSession?
    
    // MARK: Public
    func initPeerID(displayName: String) {
        self.peerID = MCPeerID.init(displayName: displayName)
    }
    
    func initDiscoveryInfo(info: [String: String]) {
        self.discoveryInfo = info
    }
    
    func initBrowser() {
        self.browser = MCNearbyServiceBrowser(peer: self.peerID!, serviceType: self.serviceType)
        self.browser?.delegate = self
    }
    
    func startBrowser() {
        self.browser?.startBrowsingForPeers()
    }
    
    func stopBrowser() {
        self.browser?.stopBrowsingForPeers()
    }
    
    func initSession() {
        self.session = MCSession(peer: self.peerID!)
        self.session?.delegate = self
    }
    
    func initAdvertiser() {
        self.advertiser = MCNearbyServiceAdvertiser(peer: self.peerID!, discoveryInfo: self.discoveryInfo, serviceType: self.serviceType)
        self.advertiser?.delegate = self
    }
    
    func startAdvertiser() {
        self.advertiser?.startAdvertisingPeer()
    }
    
    func stopAdvertiser() {
        self.advertiser?.stopAdvertisingPeer()
    }
    
    func invitePeerToSession(peerID: MCPeerID) {
        self.browser?.invitePeer(peerID, toSession: self.session!, withContext: nil, timeout: 30)
    }
    
    // MARK: MCNearbyServiceAdvertiserDelegate
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        invitationHandler(true, self.session!)
    }
    
    // MARK: MCNearbyServiceBrowserDelegate
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        delegate?.foundPeer(peerID, withDiscoveryInfo: info)
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        delegate?.lostPeer(peerID)
    }
    
    // MARK: MCSessionDelegate
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        delegate?.didReceiveData(data, fromPeer: peerID)
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {}
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {}
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {}
    
    func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {
        certificateHandler(true)
    }
}