//
//  MaxScore.swift
//  twofortyeight
//
//  Created by LongHuy Nguyen on 2/9/22.
//  Copyright © 2022 Carlos Corrêa. All rights reserved.
//

import SwiftUI

struct MaxScore: View {
	@ObservedObject var viewModel: GameViewModel
	
    var body: some View {
		Text("Max score is " + String(viewModel.MAX_SCORE))
    }
}

struct MaxScore_Previews: PreviewProvider {
    static var previews: some View {
		@State var startGame:Bool = false
		let engine = GameEngine()
		let storage = LocalStorage()
		let stateTracker = GameStateTracker(initialState: (storage.board ?? engine.blankBoard, storage.score))
		return GameView(viewModel: GameViewModel(engine, storage: storage, stateTracker: stateTracker))
    }
}
