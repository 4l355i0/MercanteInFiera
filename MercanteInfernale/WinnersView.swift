import SwiftUI

struct WinnersView: View {
    @EnvironmentObject var session: GameSession
    var body: some View { ScrollView { VStack(spacing:16){ Text("LE 5 CARTE VINCENTI").font(.title.bold()).multilineTextAlignment(.center);LazyVGrid(columns:[GridItem(.adaptive(minimum:135))],spacing:14){ForEach(session.state.winnerCardIDs,id:\.self){id in VStack{CardTile(id:id);if let owner=session.state.cards.first(where:{$0.id==id})?.ownerID,let p=session.state.player(owner){Text(p.name).font(.caption.bold())}else{Text("Nessun proprietario").font(.caption).foregroundStyle(.secondary)}}}};Divider();ForEach(session.state.players.sorted(by:{$0.balance>$1.balance})){p in HStack{Text(p.name);Spacer();Text("Credito \(p.balance)")}};Button("Nuova partita"){session.reset()}.buttonStyle(.borderedProminent).padding(.top)}.padding() } }
}
