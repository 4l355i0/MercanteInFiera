import Foundation
import MultipeerConnectivity
import Combine

@MainActor
final class GameSession: ObservableObject {
    @Published var role: PeerRole?
    @Published var playerName = ""
    @Published var state = GameState()
    @Published var errorMessage: String?
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var connectedPeers: [MCPeerID] = []
    let network = MultipeerService()
    var myID: String { network.myPeerID.displayName }
    var isMerchant: Bool { role == .merchant }

    init() {
        network.onData = { [weak self] data, peer in self?.receive(data, from: peer) }
        network.onPeersChanged = { [weak self] in guard let self else { return }; self.connectedPeers = self.network.connectedPeers; if self.isMerchant { self.syncHostPlayers(); self.broadcastState() } else if !self.network.connectedPeers.isEmpty { self.network.send(WireMessage.action(.identify(name: self.playerName))) } }
        network.onDiscoveryChanged = { [weak self] in guard let self else { return }; self.discoveredPeers = self.network.discoveredPeers }
    }
    func chooseMerchant(name: String, startingBalance: Int) { role = .merchant; playerName=name; state=GameState(); state.startingBalance=max(100,startingBalance); network.startHosting() }
    func choosePlayer(name: String) { role = .player; playerName=name; network.startBrowsing() }
    func connect(to peer: MCPeerID) { network.invite(peer) }
    func reset() { network.disconnect(); role=nil; playerName=""; state=GameState(); discoveredPeers=[]; connectedPeers=[] }
    func startGame() { guard isMerchant, state.players.count >= 2 else { return }; state.phase = .auction; broadcastState() }
    func makeLot(size: Int) { guard isMerchant, state.phase == .auction, state.auction.lot.isEmpty else { return }; let n=min(max(size,1),min(5,state.unsoldCardIDs.count)); guard n>0 else{return}; let selected=Array(state.unsoldCardIDs.shuffled().prefix(n)); state.unsoldCardIDs.removeAll{selected.contains($0)}; state.auction=AuctionState(lot:selected); broadcastState() }
    func bid(increment: Int) { guard !isMerchant else{return}; network.send(WireMessage.action(.bid(amount: state.auction.currentBid + increment))) }
    func pass() { guard !isMerchant else{return}; network.send(WireMessage.action(.pass)) }
    func awardLot() { guard isMerchant, !state.auction.lot.isEmpty, let bidder=state.auction.currentBidderID, let i=state.players.firstIndex(where:{$0.id==bidder}) else{return}; let price=state.auction.currentBid; guard state.players[i].balance >= price else { errorMessage="Credito insufficiente"; return }; state.players[i].balance -= price; state.players[i].cardIDs += state.auction.lot; for id in state.auction.lot { if let c=state.cards.firstIndex(where:{$0.id==id}) { state.cards[c].ownerID=bidder } }; state.auction=AuctionState(); broadcastState() }
    func returnLot() { guard isMerchant else{return}; state.unsoldCardIDs += state.auction.lot; state.auction=AuctionState(); broadcastState() }
    func beginElimination() { guard isMerchant, state.canBeginElimination else{return}; let w=Array((1...63).shuffled().prefix(5)); state.winnerCardIDs=w; state.callQueue=(1...63).filter{!w.contains($0)}.shuffled(); state.phase = .elimination; broadcastState() }
    func callNext() { guard isMerchant, state.phase == .elimination else{return}; guard !state.callQueue.isEmpty else { state.phase = .finished; broadcastState(); return }; let id=state.callQueue.removeFirst(); state.lastCalledCardID=id; if let i=state.cards.firstIndex(where:{$0.id==id}) { state.cards[i].eliminated=true }; if state.callQueue.isEmpty { state.phase = .finished }; broadcastState() }
    private func syncHostPlayers() { let names=Set(network.connectedPeers.map(\.displayName)); if state.phase == .lobby { state.players.removeAll{!names.contains($0.id)} }; for peer in network.connectedPeers where !state.players.contains(where:{$0.id==peer.displayName}) { if state.players.count<7 { state.players.append(PlayerState(id:peer.displayName,name:peer.displayName,balance:state.startingBalance)) } } }
    private func receive(_ data: Data, from peer: MCPeerID) { guard let msg=try? JSONDecoder().decode(WireMessage.self,from:data) else{return}; switch msg { case .state(let s): if !isMerchant { state=s }; case .action(let a): if isMerchant { handle(a,from:peer) } } }
    private func handle(_ action: ClientAction, from peer: MCPeerID) { let id=peer.displayName; switch action { case .identify(let name): if let i=state.players.firstIndex(where:{$0.id==id}) { state.players[i].name=name }; case .bid(let amount): guard state.phase == .auction, !state.auction.lot.isEmpty, !state.auction.passedPlayerIDs.contains(id), let p=state.players.first(where:{$0.id==id}), amount>state.auction.currentBid, amount<=p.balance else{return}; state.auction.currentBid=amount; state.auction.currentBidderID=id; case .pass: state.auction.passedPlayerIDs.insert(id) }; broadcastState() }
    private func broadcastState() { guard isMerchant else{return}; network.send(WireMessage.state(state)) }
}
