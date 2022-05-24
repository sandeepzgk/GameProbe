import SwiftUI
import Foundation

class GameViewController: UIHostingController<GameEntry> {
    private let viewModel: GameViewModel?
    
    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
        super.init(rootView: GameEntry(viewModel: viewModel))
        
        setupGestures()

        viewModel.start()
    }
        
    private func setupGestures() {
        view.addGestureRecognizer(Swipe(.left) { [weak self] in
            self?.viewModel?.push(.left)
        })
        view.addGestureRecognizer(Swipe(.right) { [weak self] in
            self?.viewModel?.push(.right)
        })
        view.addGestureRecognizer(Swipe(.up) { [weak self] in
            self?.viewModel?.push(.up)
        })
        view.addGestureRecognizer(Swipe(.down) { [weak self] in
            self?.viewModel?.push(.down)
        })
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
