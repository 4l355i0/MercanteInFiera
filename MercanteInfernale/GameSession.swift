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
    @Published var isDemoMode = false

    let network = MultipeerService()

    var myID: String { network.myPeerID.displayName }
    var isMerchant: Bool { role == .merchant }

    init() {
        network.onData = { [weak self] data, peer in
            self?.receive(data, from: peer)
        }

        network.onPeersChanged = { [weak self] in
            guard let self else { return }
            self.connectedPeers = self.network.connectedPeers

            if self.isMerchant {
                self.syncHostPlayers()
                self.broadcastState()
            } else if !self.network.connectedPeers.isEmpty {
                self.network.send(
                    WireMessage.action(.identify(name: self.playerName))
                )
            }
        }

        network.onDiscoveryChanged = { [weak self] in
            guard let self else { return }
            self.discoveredPeers = self.network.discoveredPeers
        }
    }

    func chooseMerchant(name: String, startingBalance: Int) {
        isDemoMode = false
        role = .merchant
        playerName = name
        state = GameState()
        state.startingBalance = max(100, startingBalance)
        network.startHosting()
    }

    func choosePlayer(name: String) {
        isDemoMode = false
        role = .player
        playerName = name
        network.startBrowsing()
    }

    func startDemo(name: String, startingBalance: Int) {
        network.disconnect()

        isDemoMode = true
        role = .merchant
        playerName = name

        state = GameState()
        state.startingBalance = max(100, startingBalance)

        state.players = [
            PlayerState(
                id: "demo-player-1",
                name: "Giocatore 1",
                balance: state.startingBalance
            ),
            PlayerState(
                id: "demo-player-2",
                name: "Giocatore 2",
                balance: state.startingBalance
            )
        ]

        state.phase = .auction
        discoveredPeers = []
        connectedPeers = []
    }

    func connect(to peer: MCPeerID) {
        network.invite(peer)
    }

    func reset() {
        network.disconnect()
        role = nil
        playerName = ""
        state = GameState()
        discoveredPeers = []
        connectedPeers = []
        isDemoMode = false
    }

    func startGame() {
        guard isMerchant, state.players.count >= 2 else { return }

        state.phase = .auction
        broadcastState()
    }

    func makeLot(size: Int) {
        guard isMerchant,
              state.phase == .auction,
              state.auction.lot.isEmpty else { return }

        let n = min(
            max(size, 1),
            min(5, state.unsoldCardIDs.count)
        )

        guard n > 0 else { return }

        let selected = Array(
            state.unsoldCardIDs.shuffled().prefix(n)
        )

        state.unsoldCardIDs.removeAll {
            selected.contains($0)
        }

        state.auction = AuctionState(lot: selected)

        broadcastState()
    }

    func bid(increment: Int) {
        guard !isMerchant else { return }

        network.send(
            WireMessage.action(
                .bid(amount: state.auction.currentBid + increment)
            )
        )
    }

    func pass() {
        guard !isMerchant else { return }

        network.send(
            WireMessage.action(.pass)
        )
    }

    func demoBid(playerID: String, increment: Int) {
        guard isDemoMode,
              isMerchant,
              state.phase == .auction,
              !state.auction.lot.isEmpty,
              let player = state.players.first(
                where: { $0.id == playerID }
              ) else { return }

        let amount = state.auction.currentBid + increment

        guard amount <= player.balance else {
            errorMessage = "Credito insufficiente per \(player.name)"
            return
        }

        state.auction.currentBid = amount
        state.auction.currentBidderID = playerID
    }

    func awardLot() {
        guard isMerchant,
              !state.auction.lot.isEmpty,
              let bidder = state.auction.currentBidderID,
              let playerIndex = state.players.firstIndex(
                where: { $0.id == bidder }
              ) else { return }

        let price = state.auction.currentBid

        guard state.players[playerIndex].balance >= price else {
            errorMessage = "Credito insufficiente"
            return
        }

        state.players[playerIndex].balance -= price
        state.players[playerIndex].cardIDs += state.auction.lot

        for id in state.auction.lot {
            if let cardIndex = state.cards.firstIndex(
                where: { $0.id == id }
            ) {
                state.cards[cardIndex].ownerID = bidder
            }
        }

        state.auction = AuctionState()

        broadcastState()
    }

    func returnLot() {
        guard isMerchant else { return }

        state.unsoldCardIDs += state.auction.lot
        state.auction = AuctionState()

        broadcastState()
    }

    func beginElimination() {
        guard isMerchant,
              state.canBeginElimination else { return }

        let winners = Array(
            (1...63).shuffled().prefix(5)
        )

        state.winnerCardIDs = winners

        state.callQueue = (1...63)
            .filter { !winners.contains($0) }
            .shuffled()

        state.phase = .elimination

        broadcastState()
    }

    func callNext() {
        guard isMerchant,
              state.phase == .elimination else { return }

        guard !state.callQueue.isEmpty else {
            state.phase = .finished
            broadcastState()
            return
        }

        let id = state.callQueue.removeFirst()

        state.lastCalledCardID = id

        if let cardIndex = state.cards.firstIndex(
            where: { $0.id == id }
        ) {
            state.cards[cardIndex].eliminated = true
        }

        if state.callQueue.isEmpty {
            state.phase = .finished
        }

        broadcastState()
    }

    private func syncHostPlayers() {
        guard !isDemoMode else { return }

        let names = Set(
            network.connectedPeers.map(\.displayName)
        )

        if state.phase == .lobby {
            state.players.removeAll {
                !names.contains($0.id)
            }
        }

        for peer in network.connectedPeers
        where !state.players.contains(
            where: { $0.id == peer.displayName }
        ) {
            if state.players.count < 7 {
                state.players.append(
                    PlayerState(
                        id: peer.displayName,
                        name: peer.displayName,
                        balance: state.startingBalance
                    )
                )
            }
        }
    }

    private func receive(
        _ data: Data,
        from peer: MCPeerID
    ) {
        guard let message = try? JSONDecoder()
            .decode(WireMessage.self, from: data)
        else {
            return
        }

        switch message {
        case .state(let newState):
            if !isMerchant {
                state = newState
            }

        case .action(let action):
            if isMerchant {
                handle(action, from: peer)
            }
        }
    }

    private func handle(
        _ action: ClientAction,
        from peer: MCPeerID
    ) {
        let id = peer.displayName

        switch action {
        case .identify(let name):
            if let index = state.players.firstIndex(
                where: { $0.id == id }
            ) {
                state.players[index].name = name
            }

        case .bid(let amount):
            guard state.phase == .auction,
                  !state.auction.lot.isEmpty,
                  !state.auction.passedPlayerIDs.contains(id),
                  let player = state.players.first(
                    where: { $0.id == id }
                  ),
                  amount > state.auction.currentBid,
                  amount <= player.balance else { return }

            state.auction.currentBid = amount
            state.auction.currentBidderID = id

        case .pass:
            state.auction.passedPlayerIDs.insert(id)
        }

        broadcastState()
    }

    private func broadcastState() {
        guard isMerchant,
              !isDemoMode else { return }

        network.send(
            WireMessage.state(state)
        )
    }
}
