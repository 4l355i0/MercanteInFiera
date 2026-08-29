import Foundation
import UIKit
import MultipeerConnectivity
import Combine

final class MultipeerService: NSObject, ObservableObject {
    static let serviceType = "mif-rb"
    @Published var connectedPeers: [MCPeerID] = []
    @Published var discoveredPeers: [MCPeerID] = []
    let myPeerID: MCPeerID
    private let session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    var onData: ((Data, MCPeerID) -> Void)?
    var onPeersChanged: (() -> Void)?
    var onDiscoveryChanged: (() -> Void)?

    override init() {
        let name = String(UIDevice.current.name.prefix(50))
        myPeerID = MCPeerID(displayName: name)
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        super.init(); session.delegate = self
    }
    func startHosting() { stopBrowsing(); advertiser?.stopAdvertisingPeer(); advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: Self.serviceType); advertiser?.delegate = self; advertiser?.startAdvertisingPeer() }
    func startBrowsing() { advertiser?.stopAdvertisingPeer(); stopBrowsing(); browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: Self.serviceType); browser?.delegate = self; browser?.startBrowsingForPeers() }
    func stopBrowsing() { browser?.stopBrowsingForPeers(); browser=nil; discoveredPeers=[] }
    func invite(_ peer: MCPeerID) { browser?.invitePeer(peer, to: session, withContext: nil, timeout: 12) }
    func disconnect() { advertiser?.stopAdvertisingPeer(); browser?.stopBrowsingForPeers(); session.disconnect(); connectedPeers=[]; discoveredPeers=[] }
    func send<T: Encodable>(_ value: T, to peers: [MCPeerID]? = nil) {
        let targets = peers ?? session.connectedPeers; guard !targets.isEmpty else { return }
        do { try session.send(JSONEncoder().encode(value), toPeers: targets, with: .reliable) } catch { print(error) }
    }
}

extension MultipeerService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) { DispatchQueue.main.async { self.connectedPeers = session.connectedPeers; self.onPeersChanged?() } }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) { DispatchQueue.main.async { self.onData?(data, peerID) } }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) { let ok = session.connectedPeers.count < 7; invitationHandler(ok, ok ? session : nil) }
}

extension MultipeerService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) { DispatchQueue.main.async { if !self.discoveredPeers.contains(peerID) { self.discoveredPeers.append(peerID); self.onDiscoveryChanged?() } } }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) { DispatchQueue.main.async { self.discoveredPeers.removeAll { $0 == peerID }; self.onDiscoveryChanged?() } }
}
