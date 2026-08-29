import SwiftUI

struct LobbyView: View {
    @EnvironmentObject var session: GameSession
    var body: some View { List { if session.isMerchant { Section("Giocatori collegati \(session.state.players.count)/7"){ ForEach(session.state.players){p in HStack{Text(p.name);Spacer();Text("\(p.balance)").foregroundStyle(.secondary)}}; if session.state.players.isEmpty {Text("In attesa…").foregroundStyle(.secondary)} } Section { Button("INIZIA PARTITA"){session.startGame()}.disabled(session.state.players.count<2) } footer:{ Text(session.state.players.count<2 ? "Servono almeno 2 giocatori." : "Pronto per iniziare.") } } else { Section("Partite vicine"){ ForEach(session.discoveredPeers,id:\.self){peer in Button(peer.displayName){session.connect(to:peer)}}; if session.discoveredPeers.isEmpty {Text("Ricerca del Mercante…").foregroundStyle(.secondary)} } Section("Connessione"){ ForEach(session.connectedPeers,id:\.self){peer in Label("Collegato a \(peer.displayName)",systemImage:"checkmark.circle.fill")} } } } }
}
