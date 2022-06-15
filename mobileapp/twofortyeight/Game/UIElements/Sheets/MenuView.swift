import SwiftUI

struct MenuView: View {
    let newGameAction: () -> ()
    let resetScoreAction: () -> ()
    @State private var showConfirmation = false
    
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .center, spacing: 16) {
				HeaderBarTitle(title: "2048 HAPTICS GAME", size: 20)
				
//                Text("Contributions:")
//				Text("Zoe Fisher")
//				Text("Harshitha Padiyar")
//				Text("Ryan Lam")
//				Text("Guangji Liu")
//				Text("Sarah Etter")
//				Text("LongHuy Nguyen")
//
//				Text("Open source project: [Link](https://github.com/caiobzen/2048-swiftui)")
                Text("2048 is a game where you combine numbered tiles in order to gain a higher numbered tile. In this game you start with two tiles, the lowest possible number available is two. Then you will play by combining the tiles with the same number to have a tile with the sum of the number on the two tiles. ")
            }
            Spacer()
        }
        .background(Color.white)
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MenuView(newGameAction:{}){}
        }
    }
}
