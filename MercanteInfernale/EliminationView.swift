import SwiftUI

struct EliminationView: View {
    @EnvironmentObject var session: GameSession; var me: PlayerState? { session.state.player(session.myID) }
    var body: some View { ScrollView { VStack(spacing:18){ Text("FASE DI CHIAMATA").font(.title2.bold()); if let id=session.state.lastCalledCardID {Text("Carta chiamata").foregroundStyle(.secondary);CardTile(id:id,eliminated:true).frame(maxWidth:260)} else {CardBack().frame(maxWidth:240);Text("Le 5 carte vincenti sono state messe da parte.").foregroundStyle(.secondary)}; if session.isMerchant {Button(session.state.callQueue.isEmpty ? "RIVELA LE VINCENTI":"CHIAMA PROSSIMA CARTA"){session.callNext()}.buttonStyle(.borderedProminent);Text("Restano da chiamare: \(session.state.callQueue.count)").font(.footnote).foregroundStyle(.secondary)}; if !session.isMerchant, let me {Divider();HStack{Text("Credito: \(me.balance)");Spacer();Text("Le mie carte")}.font(.headline);LazyVGrid(columns:[GridItem(.adaptive(minimum:105))],spacing:10){ForEach(me.cardIDs,id:\.self){id in CardTile(id:id,eliminated:session.state.cards.first(where:{$0.id==id})?.eliminated ?? false)}}} }.padding() } }
}
