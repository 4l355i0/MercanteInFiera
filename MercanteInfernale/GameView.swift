import SwiftUI

struct GameView: View { @EnvironmentObject var session: GameSession; var body: some View { switch session.state.phase { case .auction: AuctionView(); case .elimination: EliminationView(); case .finished: WinnersView(); case .lobby: LobbyView() } } }

struct AuctionView: View {
    @EnvironmentObject var session: GameSession; @State private var lotSize=1
    var me: PlayerState? { session.state.player(session.myID) }
    var body: some View { ScrollView { VStack(spacing:18) {
        if !session.isMerchant, let me { HStack{Label("Credito \(me.balance)",systemImage:"banknote");Spacer();Label("Carte \(me.cardIDs.count)",systemImage:"rectangle.stack")}.font(.headline) }
        if session.state.auction.lot.isEmpty { if session.isMerchant { VStack(spacing:12){ Text("Carte da vendere: \(session.state.unsoldCardIDs.count)").font(.title3.bold()); Stepper("Carte nel lotto: \(lotSize)",value:$lotSize,in:1...5); Button("Prepara lotto"){session.makeLot(size:lotSize)}.buttonStyle(.borderedProminent).disabled(session.state.unsoldCardIDs.isEmpty); if session.state.canBeginElimination { Button("Tutte distribuite: prepara le 5 vincenti"){session.beginElimination()}.buttonStyle(.borderedProminent) } }.padding() } else { ContentUnavailableView("In attesa del prossimo lotto",systemImage:"hourglass") } }
        else { Text("LOTTO ALL'ASTA").font(.headline); ScrollView(.horizontal){HStack{ForEach(session.state.auction.lot,id:\.self){CardTile(id:$0).frame(width:145)}}.padding(.horizontal)}; VStack(spacing:5){Text("Offerta attuale").foregroundStyle(.secondary);Text("\(session.state.auction.currentBid)").font(.system(size:42,weight:.bold,design:.rounded)); if let bidder=session.state.auction.currentBidderID, let p=session.state.player(bidder){Text(p.name).foregroundStyle(.orange)}}; if session.isMerchant { HStack{Button("Rimetti nel mazzo"){session.returnLot()};Button("AGGIUDICA"){session.awardLot()}.buttonStyle(.borderedProminent).disabled(session.state.auction.currentBidderID==nil)} } else { HStack{Button("+10"){session.bid(increment:10)}.buttonStyle(.borderedProminent);Button("+50"){session.bid(increment:50)}.buttonStyle(.borderedProminent);Button("+100"){session.bid(increment:100)}.buttonStyle(.borderedProminent)};Button("PASSO",role:.destructive){session.pass()}.buttonStyle(.bordered) } }
        if !session.isMerchant, let me, !me.cardIDs.isEmpty { Divider();Text("Le mie carte").font(.headline);LazyVGrid(columns:[GridItem(.adaptive(minimum:105))],spacing:10){ForEach(me.cardIDs,id:\.self){id in CardTile(id:id,eliminated:session.state.cards.first(where:{$0.id==id})?.eliminated ?? false)}}.padding(.horizontal) }
    }.padding(.vertical) } }
}
