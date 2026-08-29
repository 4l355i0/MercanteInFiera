import Foundation

enum PeerRole: String, Codable { case merchant, player }
enum GamePhase: String, Codable { case lobby, auction, elimination, finished }

struct CardState: Identifiable, Codable, Hashable {
    let id: Int
    var ownerID: String?
    var eliminated = false
}

struct PlayerState: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var balance: Int
    var cardIDs: [Int] = []
}

struct AuctionState: Codable, Hashable {
    var lot: [Int] = []
    var currentBid = 0
    var currentBidderID: String?
    var passedPlayerIDs: Set<String> = []
}

struct GameState: Codable, Hashable {
    var phase: GamePhase = .lobby
    var startingBalance = 1000
    var players: [PlayerState] = []
    var cards: [CardState] = (1...63).map { CardState(id: $0) }
    var unsoldCardIDs: [Int] = Array(1...63)
    var auction = AuctionState()
    var winnerCardIDs: [Int] = []
    var callQueue: [Int] = []
    var lastCalledCardID: Int?
    var canBeginElimination: Bool { unsoldCardIDs.isEmpty && auction.lot.isEmpty }
    func player(_ id: String) -> PlayerState? { players.first { $0.id == id } }
}

enum ClientAction: Codable { case identify(name: String), bid(amount: Int), pass }
enum WireMessage: Codable { case state(GameState), action(ClientAction) }
