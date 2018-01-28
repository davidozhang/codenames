import MultipeerConnectivity

protocol SCMultipeerManagerDelegate: class {
    func multipeerManager(foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?)
    func multipeerManager(lostPeer peerID: MCPeerID)
    func multipeerManager(didReceiveData data: Data, fromPeer peerID: MCPeerID)
    func multipeerManager(peerDisconnected peerID: MCPeerID)
}

class SCMultipeerManager: NSObject {
    static let instance = SCMultipeerManager()
    weak var delegate: SCMultipeerManagerDelegate?

    fileprivate let serviceType = "SpycodesV2"
    fileprivate var discoveryInfo: [String: String]?

    fileprivate var peerID: MCPeerID?
    fileprivate var advertiser: MCNearbyServiceAdvertiser?
    fileprivate var browser: MCNearbyServiceBrowser?
    fileprivate var session: MCSession?

    fileprivate var advertiserOn = false
    fileprivate var browserOn = false

    // MARK: Public

    // IMPORTANT: This method must be called prior to all other method calls!
    func setPeerID(_ displayName: String) {
        self.peerID = MCPeerID.init(displayName: displayName)
    }

    func getPeerID() -> MCPeerID? {
        return self.peerID
    }

    func startAdvertiser(discoveryInfo: [String: String]?) {
        if self.advertiserOn {
            return
        }

        self.initAdvertiser(discoveryInfo: discoveryInfo)

        self.advertiser?.startAdvertisingPeer()
        self.advertiserOn = true
    }

    func stopAdvertiser() {
        guard let _ = self.advertiser else {
            return
        }

        if !self.advertiserOn {
            return
        }

        self.advertiser?.stopAdvertisingPeer()
        self.advertiserOn = false
    }

    func startBrowser() {
        if self.browserOn {
            return
        }

        self.initBrowser()

        self.browser?.startBrowsingForPeers()
        self.browserOn = true
    }

    func stopBrowser() {
        guard let _ = self.browser else {
            return
        }

        if !self.browserOn {
            return
        }

        self.browser?.stopBrowsingForPeers()
        self.browserOn = false
    }

    func startSession() {
        guard let peerID = self.peerID else {
            return
        }

        self.session = MCSession(peer: peerID)
        self.session?.delegate = self
    }

    func stopSession() {
        guard let _ = self.session else {
            return
        }

        self.session?.disconnect()
    }

    func terminate() {
        self.stopAdvertiser()
        self.stopBrowser()
        self.stopSession()
    }

    func invitePeerToSession(_ peerID: MCPeerID) {
        guard let _ = self.browser,
              let _ = self.session else {
            return
        }

        self.browser?.invitePeer(
            peerID,
            to: self.session!,
            withContext: nil,
            timeout: 30
        )
    }

    func broadcast(_ rootObject: Any) {
        self.message(rootObject, messageType: .broadcast, toPeers: nil)
    }

    func message(_ rootObject: Any,
                 messageType: SCMultipeerMessageType,
                 toPeers: [MCPeerID]?) {
        let data = NSKeyedArchiver.archivedData(withRootObject: rootObject)
        self.sendData(data, messageType: messageType, toPeers: toPeers)
    }

    // MARK: Private
    private func initAdvertiser(discoveryInfo: [String: String]?) {
        guard let peerID = self.peerID else {
            return
        }

        self.advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: discoveryInfo,
            serviceType: self.serviceType
        )
        self.advertiser?.delegate = self
    }

    private func initBrowser() {
        guard let peerID = self.peerID else {
            return
        }

        self.browser = MCNearbyServiceBrowser(
            peer: peerID,
            serviceType: self.serviceType
        )
        self.browser?.delegate = self
    }

    private func sendData(_ data: Data,
                          messageType: SCMultipeerMessageType,
                          toPeers: [MCPeerID]?) {
        guard let _ = self.session else {
            return
        }

        do {
            if messageType == .broadcast {
                if let peers = self.session?.connectedPeers, peers.count > 0 {
                    try self.session?.send(
                        data,
                        toPeers: peers,
                        with: MCSessionSendDataMode.reliable
                    )
                }
            } else {
                if let peers = toPeers, peers.count > 0 {
                    try self.session?.send(
                        data,
                        toPeers: peers,
                        with: MCSessionSendDataMode.reliable
                    )
                }
            }
        } catch {}
    }
}

//   _____      _                 _
//  | ____|_  _| |_ ___ _ __  ___(_) ___  _ __  ___
//  |  _| \ \/ / __/ _ \ '_ \/ __| |/ _ \| '_ \/ __|
//  | |___ >  <| ||  __/ | | \__ \ | (_) | | | \__ \
//  |_____/_/\_\\__\___|_| |_|___/_|\___/|_| |_|___/

// MARK: MCNearbyServiceAdvertiserDelegate
extension SCMultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        guard let _ = self.session else {
            return
        }

        invitationHandler(true, self.session!)
    }
}

// MARK: MCNearbyServiceBrowserDelegate
extension SCMultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {
        self.delegate?.multipeerManager(foundPeer: peerID, withDiscoveryInfo: info)
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        self.delegate?.multipeerManager(lostPeer: peerID)
    }
}

// MARK: MCSessionDelegate
extension SCMultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID) {
        self.delegate?.multipeerManager(didReceiveData: data, fromPeer: peerID)
    }

    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {}

    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) {}

    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession,
                 peer peerID: MCPeerID,
                 didChange state: MCSessionState) {
        if state == MCSessionState.notConnected {
            self.delegate?.multipeerManager(peerDisconnected: peerID)
        }
    }

    func session(_ session: MCSession,
                 didReceiveCertificate certificate: [Any]?,
                 fromPeer peerID: MCPeerID,
                 certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}
