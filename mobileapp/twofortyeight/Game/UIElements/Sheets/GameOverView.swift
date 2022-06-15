import SwiftUI

@available(iOS 14.0, *)
struct GameOverView: View {
    let score: Int
    let moves: Int
    var surveyLink: String
    let skipGame: Bool
    let action: () -> ()
    
    @State var newGameButton: Bool = false
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
			HeaderBarTitle(title: "GAME ENDED", size: 60)
            Text("YOU SCORED:")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.tileEight)
            
            Text("🎉 \(score.description) 🎉")
                .font(.system(size: 50, weight: .black, design: .rounded))
                .foregroundColor(.tileDarkTitle)
            
            Text("Number of moves: \(moves)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white50)
            
            Group {
//				if #available(iOS 14.0, *) {
//                    Link("Survey Link", destination: URL(string: self.surveyLink) ?? URL(string: "https://surveymonkey.com")!)
//						.font(.system(size: 40, weight: .medium, design: .rounded))
//                        .foregroundColor(.blue)
//				} else {
//				}
                
                
                if !skipGame {
                    Button(action: openSesame) {
                        Text("Survey Link")
                    }
                    .font(.system(size: 40, weight: .medium, design: .rounded))
                    .foregroundColor(.blue)
                    
                }
                
                if newGameButton || skipGame {
                    ActionButton(title: "NEW GAME", action: action)
                }
                
            }.padding()
            Spacer()
        }
        .background(Color.white)
    }
    
    func openSesame() {
            // do something here
        print("---> about to open duckduckgo ")
        openURL(URL(string: self.surveyLink) ?? URL(string: "https://surveymonkey.com")!)
            // or/and do something here
        print("---> after openning duckduckgo ")
        newGameButton=true
    }
}

@available(iOS 14.0, *)
extension GameOverView {
    private var scoreLabel: Text {
        Text("SCORE: \(score.description)")
            .font(.system(size: 30, weight: .black, design: .rounded))
            .foregroundColor(.red)
    }
}

@available(iOS 14.0, *)
struct GameOverView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GameOverView(score: 12312, moves: 999, surveyLink: "https://www.surveymonkey.com/r/69HQVW9", skipGame: true) { }
                .environment(\.colorScheme, .light)
            
            GameOverView(score: 12312, moves: 999, surveyLink: "https://www.surveymonkey.com/r/69HQVW9", skipGame: true) { }
                .environment(\.colorScheme, .dark)
        }
    }
}
