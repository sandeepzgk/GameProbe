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
