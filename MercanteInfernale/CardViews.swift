import SwiftUI
import UIKit

private enum CardAtlas {
    static let columns = 9
    static let rows = 7
    static let source = UIImage(named: "CardsAtlas")

    static func image(for id: Int) -> UIImage? {
        guard (1...63).contains(id), let cg = source?.cgImage else { return nil }
        let index = id - 1
        let cellW = cg.width / columns
        let cellH = cg.height / rows
        let x = (index % columns) * cellW
        let y = (index / columns) * cellH
        guard let cropped = cg.cropping(to: CGRect(x: x, y: y, width: cellW, height: cellH)) else { return nil }
        return UIImage(cgImage: cropped, scale: 1, orientation: .up)
    }
}

struct CardTile: View {
    let id: Int
    var eliminated = false

    var body: some View {
        Group {
            if let card = CardAtlas.image(for: id) {
                Image(uiImage: card)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray.opacity(0.25))
                    .overlay(Text("Carta \(id)"))
                    .aspectRatio(0.714, contentMode: .fit)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .saturation(eliminated ? 0 : 1)
        .opacity(eliminated ? 0.35 : 1)
        .overlay(alignment: .topTrailing) {
            if eliminated {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.red)
                    .padding(6)
            }
        }
    }
}

struct CardBack: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14).fill(.black)
            RoundedRectangle(cornerRadius: 14).stroke(.yellow.opacity(0.75), lineWidth: 4)
            VStack(spacing: 8) {
                Image(systemName: "flame.fill").font(.system(size: 42)).foregroundStyle(.red)
                Text("MERCANTE").font(.headline.bold())
                Text("INFERNALE").font(.caption.bold()).foregroundStyle(.yellow)
            }
        }
        .aspectRatio(0.72, contentMode: .fit)
    }
}
