import SwiftUI

struct GameEntry: View {
	@ObservedObject var viewModel: GameViewModel
	@State var showLogin: Bool = true
	@State var showConsent: Bool = false
	@State var stopGame: Bool = false
	
	var body: some View {
		return VStack {
			if showLogin {
				LogInView(viewModel: viewModel, showLogin: $showLogin, showConsent: $showConsent, stopGame: $stopGame)
			}
            else if showConsent {
                let instructions = viewModel.configuration?.JSONconfig?.instructions ?? "No custom instructions :)"
                let url = viewModel.configuration?.JSONconfig?.user_instructions_image ?? URL(string: "https://www.logolynx.com/images/logolynx/7d/7d09a7f18456e08cbf106b89e750bd2d.jpeg")!
                ConsentPage(showConsent: $showConsent, instructions: instructions, url: url)
			}
			else if viewModel.isGameOver {
                let surveyLink = (self.viewModel.configuration?.JSONconfig?.survey_link ?? "https://usc.qualtrics.com/jfe/form/SV_dbfaGzKfZzEWETA") + (self.viewModel.hiddenVariables)
                GameOverView(score: self.viewModel.state.score, moves: self.viewModel.numberOfMoves, surveyLink: surveyLink) {
					self.viewModel.reset()
				}
			}
			else {
				GameView(viewModel: viewModel)
			}
		}
	}
}

struct GameView: View {
	@ObservedObject var viewModel: GameViewModel
	@State var showMenu = false
	
	var body: some View {
		VStack() {
			VStack(alignment: .center, spacing: 16) {
				Header(score: viewModel.state.score, bestScore: viewModel.MAX_SCORE, menuAction: {
					self.showMenu.toggle()
				}, undoAction: {
					self.viewModel.undo()
				}, undoEnabled: self.viewModel.isUndoable)
				GoalText()
				Board(board: viewModel.state.board, addedTile: viewModel.addedTile)
				Moves(viewModel.numberOfMoves)
			}
			
			VStack() {
				Text("User id: " + self.viewModel.userId).bold()
				Text("Experiment id: " + self.viewModel.experimentId).bold()
			}
			.font(.system(size: 16, weight: .regular, design: .rounded))
			.foregroundColor(.white50)
		}
		.frame(minWidth: .zero,
			   maxWidth: .infinity,
			   minHeight: .zero,
			   maxHeight: .infinity,
			   alignment: .center)
			.background(Color.gameBackground)
			.background(Menu())
			.edgesIgnoringSafeArea(.all)
	}
}

extension GameView {
	
	private func Menu() -> some View {
		EmptyView().sheet(isPresented: $showMenu) {
			MenuView(newGameAction: {
				self.viewModel.reset()
				self.showMenu.toggle()
			}, resetScoreAction: {
				self.viewModel.eraseBestScore()
				self.showMenu.toggle()
			})
		}
	}
	
	private func GameOver() -> some View {
		EmptyView().sheet(isPresented: $viewModel.isGameOver) {
            GameOverView(score: self.viewModel.state.score, moves: self.viewModel.numberOfMoves, surveyLink: self.viewModel.configuration!.JSONconfig!.survey_link) {
				self.viewModel.reset()
			}
		}
	}
}

struct GameView_Previews: PreviewProvider {
	static var previews: some View {
		@State var startGame:Bool = false
		let engine = GameEngine()
		let storage = LocalStorage()
		let stateTracker = GameStateTracker(initialState: (storage.board ?? engine.blankBoard, storage.score))
		return GameView(viewModel: GameViewModel(engine, storage: storage, stateTracker: stateTracker))
	}
}
