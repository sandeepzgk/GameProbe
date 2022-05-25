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
    
//    public var config_id: String? {
//        didSet {
//            print("set config_id: \(config_id)")
//            self.configuration = Configuration(config_id: self.config_id!)
//            if let max_score_string = self.configuration?.JSONconfig?.max_score, let max_score = Int(max_score_string) {
//                self.MAX_SCORE = max_score
//            }
//            if !configHiddenVariablesDone {
//                self.hiddenVariables += "&config_id=" + (config_id ?? "")
//                self.configHiddenVariablesDone = true
//                if userHiddenVariablesDone {
//                    self.hiddenVariables = self.hiddenVariables.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
//                }
//            }
//        }
//    }
    
    public var config_id: String? {
        didSet {
            print("set config_id: \(config_id)")
            self.configuration = Configuration(config_id: self.config_id!)
            if let max_score=self.configuration?.JSONconfig?.experimentMaxscore {
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
    /**
    DESCR: Initializes the LofeltHaptics Suite
    INPUT: na
    RET  : the function returns true, if it successfully intialized or false if it failed to initialize.
    **/
    func setupHaptics() -> Bool{
        do {
            self.haptics = try LofeltHaptics.init()
            return true
        } catch let error {
            print("Lofelt Haptics Engine Creation Error: \(error)")
            return false
        }
    }
    
    /**
    DESCR: Check if the iOS meets minimum requirements to make sure it works.
    INPUT: na
    RET  : return true if it meets requirement, else return false. Important for the game engine to know that it does not qualify to use this particular device for the experiment so a error should be shown to the user.
    DOC: https://developer.lofelt.com/integrating-haptics/studio-framework-for-ios/#integrating-haptics-using-the-studio-framework-for-ios  deviceMeetsMinimumRequirements
    **/
    func checkDevRequirements() -> Bool{
        let meetDeviceRequire=try LofeltHaptics.deviceMeetsMinimumRequirement();
        if(!meetDeviceRequire){
            //@TODO: Kill the game when the device does not meet the device requirements
        }
        return meetDeviceRequire
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

//struct ConfigBody: Codable {
//    let user_instructions_image: URL
//    let gesture: String
//    let long_haptics_file: URL
//    let short_haptics_file: URL
//    var survey_link: String
//    let instructions: String
//    let max_score: String?
//}

struct expidError: Codable{
    let error: String
}

struct ConfigElement: Codable {
    let interactionType, experimentDescription: String
    let experimentMaxscore: Int
    let surveyURL: String
    let userAgreements: [String]
    let userInstructions, expid, email: String
    let linkedFiles: LinkedFiles

    enum CodingKeys: String, CodingKey {
        case interactionType = "interaction_type"
        case experimentDescription = "experiment_description"
        case experimentMaxscore = "experiment_maxscore"
        case surveyURL = "survey_url"
        case userAgreements = "user_agreements"
        case userInstructions = "user_instructions"
        case expid, email
        case linkedFiles = "linked_files"
    }
}
struct ConfigBody: Codable {
    let interactionType, experimentDescription: String
    let experimentMaxscore: Int
    let surveyURL: String
    let userAgreements: [String]
    let userInstructions, expid, email: String
    let linkedFiles: LinkedFiles

    enum CodingKeys: String, CodingKey {
        case interactionType = "interaction_type"
        case experimentDescription = "experiment_description"
        case experimentMaxscore = "experiment_maxscore"
        case surveyURL = "survey_url"
        case userAgreements = "user_agreements"
        case userInstructions = "user_instructions"
        case expid, email
        case linkedFiles = "linked_files"
    }
}
// MARK: - LinkedFiles
struct LinkedFiles: Codable {
    let instructionImage, shortEffect, longEffect, longAudio: URL

    enum CodingKeys: String, CodingKey {
        case instructionImage = "instruction_image"
        case shortEffect = "short_effect"
        case longEffect = "long_effect"
        case longAudio = "long_audio"
    }
}



class Configuration {
    var JSONconfig: ConfigBody?
    var JSONarray: ConfigArray?
    var expidErrorJson: expidError?
    let config_id: String
    let downloadCondition: NSCondition
    private var reconnect_num=0;
    private let MAX_RETRY_NUM = 2;
    private let secondsToDelay=5.0;
    var startGameButtonActive=true;
    var downloaded = false {
        didSet {
            if self.downloaded && oldValue == false {
                errorMsg = ""
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
    
//    func getConfig() {
//        let url = URL(string: "https://haptics-test.herokuapp.com/config/getConfig")!
//        var request = URLRequest(url: url)
//        let bodyData = try? JSONSerialization.data(
//            withJSONObject: [
//                "config_id": config_id
//            ],
//            options: []
//        )
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpBody = bodyData
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//            if let data = data {
//                let jsonDecoder = JSONDecoder()
//                do {
//                    self.JSONconfig = try jsonDecoder.decode(ConfigBody.self, from: data)
//                    self.downloadContent()
//                }
//                catch {
//                    print(error)
//                    if(error.localizedDescription == "The data couldn’t be read because it is missing.") {
//                        self.errorMsg = "invalid experiment id"
//                    } else {
//                        self.errorMsg = "please restart the server"
//                    }
//                    self.downloadCondition.signal()
//                }
//            } else {
//                print("no data returned, server is down")
//                self.errorMsg = "please restart the server"
//                self.downloadCondition.signal()
//            }
//        }
//        task.resume()
//    }
    typealias ConfigArray = [ConfigBody]
    func getConfig() {
        let url = URL(string: "https://t8fqmzvdd7.execute-api.us-east-1.amazonaws.com/getById")!
        var request = URLRequest(url: url)
        let bodyData = try? JSONSerialization.data(
            withJSONObject: [
                "expid": config_id.uppercased()
            ],
            options: []
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0); //use the semaphore to make the task, request JSON from server a synchronize function call
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            let httpResponse = response as? HTTPURLResponse
            print(httpResponse?.statusCode)
            if (httpResponse?.statusCode == 503){
                if(self.reconnect_num<self.MAX_RETRY_NUM){
                    print("reconnect retry request server")
                    //self.errorMsg = "re request server"
                    self.reconnect_num+=1;
                    semaphore.signal();
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.secondsToDelay) {
                        print("This message is delayed")
                        self.getConfig();
                    }
                }
                else {
                    self.errorMsg = "Server is Down"
                    semaphore.signal();
                }
                
            }
            else if (httpResponse?.statusCode == 404){
                self.errorMsg = "Experiment id is wrong!"
                semaphore.signal();
            }
            else if (httpResponse?.statusCode == 200){
                if let data = data {
                    let jsonDecoder = JSONDecoder()
                    do {
                        print(data);
                        self.JSONarray = try jsonDecoder.decode(ConfigArray.self, from: data)
                        if let config_body = self.JSONarray?[0] {
                            self.JSONconfig=config_body;
                        }
                        print("success request server");
                        self.errorMsg = ""
                        //self.reconnect_num=0;
                        semaphore.signal();
                        self.downloadContent()
                    }
                    catch {
                        self.downloadCondition.signal()
                    }
                    
                } else {
                    print("experiment id is wrong")
                    self.errorMsg = "experiment id is wrong";
                    semaphore.signal();
                    self.downloadCondition.signal()
                }
            }
            else{
                self.errorMsg = "Unkown error";
                semaphore.signal();
            }
            
        }
            
        task.resume();
        semaphore.wait()
        
    }
    
    /**
    DESCR: Requests and downloads the JSON config file from our server
    INPUT: Requires, two parameters, one is the postURL
    RET  : the function returns true, it success or false
    DOC: https://developer.lofelt.com/integrating-haptics/studio-framework-for-ios/#play-haptic-with-audio
    **/
    func requestJSONConfig(postURL:URL, expID:NSString){
        var request = URLRequest(url: postURL)
        let bodyData = try? JSONSerialization.data(
            withJSONObject: [
                "expid": config_id
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
//    func downloadContent() {
//        if let url = self.JSONconfig?.short_haptics_file {
//            let downloadTaskShort = URLSession.shared.downloadTask(with: url) {
//                        urlOrNil, responseOrNil, errorOrNil in
//
//                guard let fileURL = urlOrNil else { return }
//                do {
//                    try self.hapticDataShort = NSString(contentsOf: fileURL, encoding: String.Encoding.utf8.rawValue)
//                    print("downloaded short haptic")
//                } catch {
//                    print ("Error Downloading short Haptic from Aws: \(error)")
//                }
//            }
//            downloadTaskShort.resume()
//        } else {
//            print("invalid url for short haptics file")
//        }
//
//        if let url = self.JSONconfig?.long_haptics_file {
//            let downloadTaskLong = URLSession.shared.downloadTask(with: url) {
//                urlOrNil, responseOrNil, errorOrNil in
//
//                guard let fileURL = urlOrNil else { return }
//                do {
//                    try self.hapticDataLong = NSString(contentsOf: fileURL, encoding: String.Encoding.utf8.rawValue)
//                    print("downloaded long haptic")
//                } catch {
//                    print ("Error Downloading long Haptic from Aws: \(error)")
//                }
//            }
//            downloadTaskLong.resume()
//        } else {
//            print("invalid url for short hapitcs file")
//        }
//    }
    func downloadContent() {
        if let url = self.JSONconfig?.linkedFiles.shortEffect {
            let downloadTaskShort = URLSession.shared.downloadTask(with: url) {
                        urlOrNil, responseOrNil, errorOrNil in
                        
                guard let fileURL = urlOrNil else { return }
                do {
                    try self.hapticDataShort = NSString(contentsOf: fileURL, encoding: String.Encoding.utf8.rawValue)
                    print("downloaded short haptic")
                    self.startGameButtonActive=false;
                } catch {
                    print ("Error Downloading short Haptic from Aws: \(error)")
                    self.startGameButtonActive=true;
                }
            }
            downloadTaskShort.resume()
        } else {
            print("invalid url for short haptics file")
        }
        
        if let url = self.JSONconfig?.linkedFiles.longEffect {
            let downloadTaskLong = URLSession.shared.downloadTask(with: url) {
                urlOrNil, responseOrNil, errorOrNil in

                guard let fileURL = urlOrNil else { return }
                do {
                    try self.hapticDataLong = NSString(contentsOf: fileURL, encoding: String.Encoding.utf8.rawValue)
                    print("downloaded long haptic")
                    self.startGameButtonActive=false;
                } catch {
                    print ("Error Downloading long Haptic from Aws: \(error)")
                    self.startGameButtonActive=true;
                }
            }
            downloadTaskLong.resume()
        } else {
            print("invalid url for short hapitcs file")
        }
    }
}
