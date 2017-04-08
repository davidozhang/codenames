import MultipeerConnectivity

protocol SCMultipeerManagerDelegate: class {
    func foundPeer(_ peerID: MCPeerID, withDiscoveryInfo info: [String: String]?)
    func lostPeer(_ peerID: MCPeerID)
    func didReceiveData(_ data: Data, fromPeer peerID: MCPeerID)
    func peerDisconnectedFromSession(_ peerID: MCPeerID)
}

class SCMultipeerManager: NSObject {
    static let instance = SCMultipeerManager()
    weak var delegate: SCMultipeerManagerDelegate?

    fileprivate let serviceType = "Spycodes"
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
        guard let _ = self.browser else {
            return
        }

        self.browser?.invitePeer(
            peerID,
            to: self.session!,
            withContext: nil,
            timeout: 30
        )
    }

    func broadcastData(_ data: Data) {
        guard let _ = self.session else {
            return
        }

        do {
            if let connectedPeers = self.session?.connectedPeers, connectedPeers.count > 0 {
                try self.session?.send(
                    data,
                    toPeers: connectedPeers,
                    with: MCSessionSendDataMode.reliable
                )
            }
        } catch {}
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
        delegate?.foundPeer(peerID, withDiscoveryInfo: info)
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        delegate?.lostPeer(peerID)
    }
}

// MARK: MCSessionDelegate
extension SCMultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID) {
        delegate?.didReceiveData(data, fromPeer: peerID)
    }

    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {}

    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL,
                 withError error: Error?) {}

    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession,
                 peer peerID: MCPeerID,
                 didChange state: MCSessionState) {
        if state == MCSessionState.notConnected {
            delegate?.peerDisconnectedFromSession(peerID)
        }
    }

    func session(_ session: MCSession,
                 didReceiveCertificate certificate: [Any]?,
                 fromPeer peerID: MCPeerID,
                 certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}
