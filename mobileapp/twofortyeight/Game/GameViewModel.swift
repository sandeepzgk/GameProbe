import Combine
import UIKit
import LofeltHaptics
import DeviceKit

class GameViewModel: ObservableObject {
    private(set) var engine: Engine
    private(set) var storage: Storage
    private(set) var stateTracker: StateTracker
    private var haptics: LofeltHaptics?
    var configuration: Configuration?
    public var userId: String = "" {
        didSet {
            if !userHiddenVariablesDone {
                self.hiddenVariables += "&user_id=" + userId
                self.userHiddenVariablesDone = true
                if configHiddenVariablesDone {
                    self.hiddenVariables = self.hiddenVariables.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                }
            }
        }
    }
    
	public var experimentId: String = ""
	public var skipGame: Bool = false
    public var hiddenVariables: String
    var configHiddenVariablesDone = false
    var userHiddenVariablesDone = false
    
	public var MAX_SCORE = 40
  
    @Published var isGameOver = false {
        didSet {
            if isGameOver {
                if let hapticData = self.configuration?.hapticDataLong {
                    self.playHaptic(hapticData: hapticData)
                }
            }
        }
    }
    
    public var config_id: String? {
        didSet {
            print("set config_id: \(config_id)")
            self.configuration = Configuration(config_id: self.config_id!)
            if let max_score_string = self.configuration?.JSONconfig?.max_score, let max_score = Int(max_score_string) {
                self.MAX_SCORE = max_score
            }
            if !configHiddenVariablesDone {
                self.hiddenVariables += "&config_id=" + (config_id ?? "")
                self.configHiddenVariablesDone = true
                if userHiddenVariablesDone {
                    self.hiddenVariables = self.hiddenVariables.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                }
            }
        }
    }
    
    private(set) var addedTile: (Int, Int)? = nil
    
    private(set) var bestScore: Int = .zero {
        didSet { storage.save(bestScore: bestScore) }
    }
    
    var numberOfMoves: Int {
        return stateTracker.statesCount - 1
    }
    
    var isUndoable: Bool {
        return stateTracker.isUndoable
    }
    var state: GameState {
        didSet {
            bestScore = max(bestScore, state.score)
            storage.save(score: state.score)
			isGameOver = (state.score > MAX_SCORE || engine.isGameOver(state.board))
            storage.save(board: state.board)
        }
    }
    
    init(_ engine: Engine, storage: Storage, stateTracker: StateTracker) {
        self.engine = engine
        self.storage = storage
        self.stateTracker = stateTracker
        self.state = stateTracker.last
        self.bestScore = max(storage.bestScore, storage.score)
        self.hiddenVariables = "?os=" + UIDevice.current.systemName + " " + UIDevice.current.systemVersion
        self.hiddenVariables += "&model=" + Device.current.description
        self.hiddenVariables += "&vendor_id=" + (UIDevice.current.identifierForVendor?.uuidString ?? "")
        self.setupHaptics()
    }
    
    func start() {
        if state.board.isMatrixEmpty { reset() }
    }
    
    func setupHaptics() {
        do {
            self.haptics = try LofeltHaptics.init()
        } catch let error {
            print("Lofelt Haptics Engine Creation Error: \(error)")
            return
        }
    }

    func addNumber() {
        let result = engine.addNumber(state.board)
        state = stateTracker.updateCurrent(with: result.newBoard)
        addedTile = result.addedTile
    }

    func push(_ direction: Direction) {
        let result = engine.push(state.board, to: direction)
        let boardHasChanged = !state.board.isEqual(result.newBoard)
        state = stateTracker.next(with: (result.newBoard, state.score + result.scoredPoints))
        if boardHasChanged {
            addNumber()
        }
        if result.scoredPoints > 0 {
            if let hapticData = self.configuration?.hapticDataShort {
                playHaptic(hapticData: hapticData)
            }
        }
    }
    
    func playHaptic(hapticData: NSString?) {
        // Load it into the LofeltHaptics object as a String.
        guard let haptics = self.haptics else {
            print("unable to use haptics object")
            return
        }
        guard let hapticData = hapticData else { return }
        do {
            try haptics.load(hapticData as String)
            try haptics.play()
            print("Successfully played haptic!")
        } catch {
            print("Could not play haptic clip")
        }
        
    }
    
    func undo() {
        state = stateTracker.undo()
    }
    
    func reset() {
        state = stateTracker.reset(with: (engine.blankBoard, .zero))
        addNumber()
    }
    
    func eraseBestScore() {
        bestScore = .zero
    }
    
}

struct ConfigBody: Codable {
    let user_instructions_image: URL
    let gesture: String
    let long_haptics_file: URL
    let short_haptics_file: URL
    var survey_link: String
    let instructions: String
    let max_score: String?
}

class Configuration {
    var JSONconfig: ConfigBody?
    let config_id: String
    let downloadCondition: NSCondition
    var downloaded = false {
        didSet {
            if self.downloaded && oldValue == false {
                errorMsg = nil
                self.downloadCondition.signal()
            }
        }
    }
    var errorMsg: String?
        
    var hapticDataShort: NSString? {
        didSet {
            if let _ = self.hapticDataShort, let _ = self.hapticDataLong {
                self.downloaded = true
            } else {
                self.downloaded = false
            }
        }
    }
    
    var hapticDataLong: NSString? {
        didSet {
            if let _ = self.hapticDataShort, let _ = self.hapticDataLong {
                self.downloaded = true
            } else {
                self.downloaded = false
            }
        }
    }
    
    init(config_id: String) {
        self.config_id = config_id
        self.downloadCondition = NSCondition()
        getConfig()
        self.downloadCondition.lock()
        if (self.hapticDataShort == nil || self.hapticDataLong == nil) {
            self.downloadCondition.wait(until: Date(timeIntervalSinceNow: 5))
        }
    }
    
    func getConfig() {
        let url = URL(string: "https://haptics-test.herokuapp.com/config/getConfig")!
        var request = URLRequest(url: url)
        let bodyData = try? JSONSerialization.data(
            withJSONObject: [
                "config_id": config_id
            ],
            options: []
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                let jsonDecoder = JSONDecoder()
                do {
                    self.JSONconfig = try jsonDecoder.decode(ConfigBody.self, from: data)
                    self.downloadContent()
                }
                catch {
                    print(error)
                    if(error.localizedDescription == "The data couldn’t be read because it is missing.") {
                        self.errorMsg = "invalid experiment id"
                    } else {
                        self.errorMsg = "please restart the server"
                    }
                    self.downloadCondition.signal()
                }
            } else {
                print("no data returned, server is down")
                self.errorMsg = "please restart the server"
                self.downloadCondition.signal()
            }
        }
        task.resume()
    }
    
    func downloadContent() {
        if let url = self.JSONconfig?.short_haptics_file {
            let downloadTaskShort = URLSession.shared.downloadTask(with: url) {
                        urlOrNil, responseOrNil, errorOrNil in
                        
                guard let fileURL = urlOrNil else { return }
                do {
                    try self.hapticDataShort = NSString(contentsOf: fileURL, encoding: String.Encoding.utf8.rawValue)
                    print("downloaded short haptic")
                } catch {
                    print ("Error Downloading short Haptic from Aws: \(error)")
                }
            }
            downloadTaskShort.resume()
        } else {
            print("invalid url for short haptics file")
        }
        
        if let url = self.JSONconfig?.long_haptics_file {
            let downloadTaskLong = URLSession.shared.downloadTask(with: url) {
                urlOrNil, responseOrNil, errorOrNil in

                guard let fileURL = urlOrNil else { return }
                do {
                    try self.hapticDataLong = NSString(contentsOf: fileURL, encoding: String.Encoding.utf8.rawValue)
                    print("downloaded long haptic")
                } catch {
                    print ("Error Downloading long Haptic from Aws: \(error)")
                }
            }
            downloadTaskLong.resume()
        } else {
            print("invalid url for short hapitcs file")
        }
    }
}
