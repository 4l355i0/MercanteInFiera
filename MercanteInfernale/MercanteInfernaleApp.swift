import SwiftUI

@main
struct MercanteInfernaleApp: App {
    @StateObject private var session = GameSession()
    var body: some Scene { WindowGroup { RootView().environmentObject(session).preferredColorScheme(.dark) } }
}
