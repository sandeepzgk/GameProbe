import SwiftUI

struct LogInView: View {
	@ObservedObject var viewModel: GameViewModel
	@Binding var showLogin: Bool
	@Binding var showConsent:Bool
	@Binding var stopGame:Bool
    @Binding var errorString:String
    @State private var userId: String = ""
	@State private var experimentId: String = ""
	
    init(viewModel: GameViewModel, showLogin: Binding<Bool>, showConsent: Binding<Bool>, stopGame: Binding<Bool>, errorString: Binding<String>){
        _showLogin=showLogin
        _showConsent=showConsent
        _stopGame=stopGame
        _errorString=errorString
        self.viewModel=viewModel
        self._userId=State(initialValue: viewModel.userId)
    
    }
    
	var body: some View {
		VStack(alignment: .center, spacing: 20) {
			HeaderBarTitle(title: "2048 HAPTICS GAME", size: 20)
			
			TextField(
                "User id",
				text: $userId
                //text: self.viewModel.userId
			)
			.frame(height: 55)
			.textFieldStyle(PlainTextFieldStyle())
			.padding([.horizontal], 4)
			.cornerRadius(10)
			.overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray))
			.padding([.horizontal], 24)
			
			TextField(
				"Experiment id",
				text: $experimentId
			)
			.frame(height: 55)
			.textFieldStyle(PlainTextFieldStyle())
			.padding([.horizontal], 4)
			.cornerRadius(10)
			.overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray))
			.padding([.horizontal], 24)
			
			Button(action: {
				self.viewModel.experimentId = self.experimentId
				self.viewModel.userId = self.userId
				self.viewModel.config_id = self.experimentId
				self.viewModel.configuration?.getConfig()
				self.viewModel.reset()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // asynchronize wait for file downloading to finish
                    if let startButtonActive = self.viewModel.configuration?.startGameButtonActive {
                        if(startButtonActive){
                            self.showLogin = true
                        }
                        else{
                            self.showConsent = true
                            self.showLogin = false
                        }
                        
                    }
                    if let errorMsg_str = self.viewModel.configuration?.errorMsg {
                        self.errorString=errorMsg_str;
                        
                    }
                }
                
			}) {
				Text("Start game")
			}
            .disabled(userId.isEmpty || experimentId.isEmpty)
			.foregroundColor(.white)
			.padding()
			.background((userId.isEmpty || experimentId.isEmpty) ? Color.gray : Color.accentColor)
			.cornerRadius(8)
			
			Button(action: {
				self.viewModel.reset()
				self.viewModel.skipGame = true
				self.showLogin = false
			}) {
				Text("Skip >>")
			}
			
            Text(self.errorString).foregroundColor(Color.red)
		}
	}
}
