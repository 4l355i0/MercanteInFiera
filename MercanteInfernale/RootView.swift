import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: GameSession

    var body: some View {
        NavigationStack {
            Group {
                if session.role == nil {
                    RoleSelectionView()
                } else if session.state.phase == .lobby {
                    LobbyView()
                } else {
                    GameView()
                }
            }
            .navigationTitle("Mercante Infernale")
            .toolbar {
                if session.role != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Esci") {
                            session.reset()
                        }
                    }
                }
            }
        }
        .tint(.orange)
        .alert(
            "Attenzione",
            isPresented: Binding(
                get: { session.errorMessage != nil },
                set: { if !$0 { session.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                session.errorMessage = nil
            }
        } message: {
            Text(session.errorMessage ?? "")
        }
    }
}

struct RoleSelectionView: View {
    @EnvironmentObject var session: GameSession
    @State private var name = ""
    @State private var balance = 1000

    var body: some View {
        Form {
            Section("Nome") {
                TextField("Il tuo nome", text: $name)
            }

            Section("Crea partita") {
                Stepper(
                    "Credito iniziale: \(balance)",
                    value: $balance,
                    in: 100...10_000,
                    step: 100
                )

                Button("Sono il Mercante") {
                    session.chooseMerchant(
                        name: name.isEmpty ? "Mercante" : name,
                        startingBalance: balance
                    )
                }
                .buttonStyle(.borderedProminent)
            }

            Section("Entra in partita") {
                Button("Sono un Giocatore") {
                    session.choosePlayer(
                        name: name.isEmpty ? "Giocatore" : name
                    )
                }
            }

            Section {
                Text("3–8 partecipanti totali: 1 Mercante e da 2 a 7 giocatori.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
