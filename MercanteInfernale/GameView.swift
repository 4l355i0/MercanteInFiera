import SwiftUI

struct GameView: View {
    @EnvironmentObject var session: GameSession
    @State private var lotSize = 1

    var body: some View {
        List {
            if session.isMerchant {
                merchantView
            } else {
                playerView
            }
        }
        .navigationTitle(title)
    }

    private var title: String {
        switch session.state.phase {
        case .lobby:
            return "Lobby"
        case .auction:
            return "Asta"
        case .elimination:
            return "Eliminazione"
        case .finished:
            return "Vincitori"
        }
    }

    @ViewBuilder
    private var merchantView: some View {
        switch session.state.phase {
        case .lobby:
            Section("Lobby") {
                Text("In attesa dei giocatori...")
            }

        case .auction:
            auctionMerchantView

        case .elimination:
            eliminationMerchantView

        case .finished:
            winnersView
        }
    }

    @ViewBuilder
    private var playerView: some View {
        switch session.state.phase {
        case .lobby:
            Section("Lobby") {
                Text("Attendi che il Mercante inizi la partita.")
            }

        case .auction:
            auctionPlayerView

        case .elimination:
            eliminationPlayerView

        case .finished:
            winnersView
        }
    }

    private var auctionMerchantView: some View {
        Group {
            Section("Carte ancora da vendere") {
                Text("\(session.state.unsoldCardIDs.count)")
                    .font(.title2.bold())
            }

            if session.state.auction.lot.isEmpty {
                Section("Nuovo lotto") {
                    Stepper(
                        "Carte nel pacchetto: \(lotSize)",
                        value: $lotSize,
                        in: 1...5
                    )

                    Button("CREA LOTTO") {
                        session.makeLot(size: lotSize)
                    }
                    .disabled(session.state.unsoldCardIDs.isEmpty)
                }
            } else {
                Section("Lotto all'asta") {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(session.state.auction.lot, id: \.self) { id in
                                cardThumb(id: id)
                            }
                        }
                    }

                    HStack {
                        Text("Offerta")
                        Spacer()
                        Text("\(session.state.auction.currentBid)")
                            .font(.title2.bold())
                    }

                    if let bidderID = session.state.auction.currentBidderID,
                       let bidder = session.state.players.first(
                        where: { $0.id == bidderID }
                       ) {
                        Text("Miglior offerente: \(bidder.name)")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Nessuna offerta")
                            .foregroundStyle(.secondary)
                    }
                }

                if session.isDemoMode {
                    Section("Simula offerte") {
                        ForEach(session.state.players) { player in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(player.name)
                                    Spacer()
                                    Text("Credito \(player.balance)")
                                        .foregroundStyle(.secondary)
                                }

                                HStack {
                                    Button("+10") {
                                        session.demoBid(
                                            playerID: player.id,
                                            increment: 10
                                        )
                                    }

                                    Button("+50") {
                                        session.demoBid(
                                            playerID: player.id,
                                            increment: 50
                                        )
                                    }

                                    Button("+100") {
                                        session.demoBid(
                                            playerID: player.id,
                                            increment: 100
                                        )
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section {
                    Button("AGGIUDICA LOTTO") {
                        session.awardLot()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(session.state.auction.currentBidderID == nil)

                    Button("RIMETTI LE CARTE NEL MAZZO") {
                        session.returnLot()
                    }
                    .foregroundStyle(.red)
                }
            }

            Section("Giocatori") {
                ForEach(session.state.players) { player in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(player.name)
                            Spacer()
                            Text("\(player.balance)")
                        }

                        Text("\(player.cardIDs.count) carte")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if session.state.canBeginElimination {
                Section {
                    Button("FINE ASTE — INIZIA ELIMINAZIONE") {
                        session.beginElimination()
                    }
                    .buttonStyle(.borderedProminent)
                } footer: {
                    Text("L'app nasconderà casualmente 5 carte vincenti e chiamerà tutte le altre.")
                }
            }
        }
    }

    private var auctionPlayerView: some View {
        Group {
            if session.state.auction.lot.isEmpty {
                Section {
                    Text("Il Mercante sta preparando il prossimo lotto.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Lotto all'asta") {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(session.state.auction.lot, id: \.self) { id in
                                cardThumb(id: id)
                            }
                        }
                    }

                    HStack {
                        Text("Offerta attuale")
                        Spacer()
                        Text("\(session.state.auction.currentBid)")
                            .font(.title2.bold())
                    }
                }

                Section("La tua offerta") {
                    HStack {
                        Button("+10") {
                            session.bid(increment: 10)
                        }

                        Button("+50") {
                            session.bid(increment: 50)
                        }

                        Button("+100") {
                            session.bid(increment: 100)
                        }
                    }
                    .buttonStyle(.bordered)

                    Button("PASSO") {
                        session.pass()
                    }
                    .foregroundStyle(.red)
                }
            }

            myCardsSection
        }
    }

    private var eliminationMerchantView: some View {
        Group {
            Section("Eliminazione") {
                if let id = session.state.lastCalledCardID {
                    VStack(spacing: 12) {
                        Text("Ultima carta chiamata")
                            .foregroundStyle(.secondary)

                        cardLarge(id: id)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Text("Le 5 carte vincenti sono state nascoste.")
                }

                Text("Carte ancora da chiamare: \(session.state.callQueue.count)")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(
                    session.state.callQueue.isEmpty
                    ? "MOSTRA I VINCITORI"
                    : "CHIAMA PROSSIMA CARTA"
                ) {
                    session.callNext()
                }
                .buttonStyle(.borderedProminent)
            }

            Section("Situazione giocatori") {
                ForEach(session.state.players) { player in
                    let activeCards = player.cardIDs.filter { id in
                        !session.state.cards.first(
                            where: { $0.id == id }
                        )!.eliminated
                    }

                    VStack(alignment: .leading) {
                        Text(player.name)
                        Text("\(activeCards.count) carte ancora vive")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var eliminationPlayerView: some View {
        Group {
            if let id = session.state.lastCalledCardID {
                Section("Carta chiamata") {
                    cardLarge(id: id)
                        .frame(maxWidth: .infinity)
                }
            }

            myCardsSection
        }
    }

    private var winnersView: some View {
        Group {
            Section("Le 5 carte vincenti") {
                ForEach(session.state.winnerCardIDs, id: \.self) { id in
                    VStack(alignment: .leading, spacing: 8) {
                        cardLarge(id: id)

                        if let card = session.state.cards.first(
                            where: { $0.id == id }
                        ),
                           let ownerID = card.ownerID,
                           let owner = session.state.players.first(
                            where: { $0.id == ownerID }
                           ) {
                            Text("Vince: \(owner.name)")
                                .font(.headline)
                        } else {
                            Text("Carta non assegnata")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var myCardsSection: some View {
        Section("Le tue carte") {
            if let me = session.state.players.first(
                where: { $0.id == session.myID }
            ) {
                if me.cardIDs.isEmpty {
                    Text("Nessuna carta")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(me.cardIDs, id: \.self) { id in
                        HStack {
                            cardThumb(id: id)

                            Spacer()

                            if let card = session.state.cards.first(
                                where: { $0.id == id }
                            ),
                               card.eliminated {
                                Label(
                                    "Eliminata",
                                    systemImage: "xmark.circle.fill"
                                )
                                .foregroundStyle(.red)
                            }
                        }
                    }
                }

                HStack {
                    Text("Credito")
                    Spacer()
                    Text("\(me.balance)")
                        .font(.headline)
                }
            } else {
                Text("Profilo giocatore non trovato")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func cardThumb(id: Int) -> some View {
    CardTile(id: id, eliminated: false)
        .frame(width: 88, height: 132)
}

private func cardLarge(id: Int) -> some View {
    CardTile(id: id, eliminated: false)
        .frame(width: 180, height: 270)
}
}
