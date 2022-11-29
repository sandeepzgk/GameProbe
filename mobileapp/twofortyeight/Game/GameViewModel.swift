import Combine
import UIKit
import DeviceKit
import AVFoundation
import CoreHaptics

class GameViewModel: ObservableObject {
    private(set) var engine: Engine
    private(set) var storage: Storage
    private(set) var stateTracker: StateTracker
    private var hapticEngine: CHHapticEngine?
    
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
    public var GameStart = false
    var playLongEffect = true
    
	public var MAX_SCORE = 40
  
    @Published var isGameOver = false {
        didSet {
            if isGameOver&&playLongEffect&&GameStart {
                playLongEffect = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("play haptic long effect")
                    if let hapticUrl = self.configuration?.longHapticAHAPurl {
                        print("play haptic short effect")
                        self.playAHAPHaptic(hapticUrl: hapticUrl)
                    }
                    if let longAudioUrl = self.configuration?.longAudioLocalUrl {
                        self.play(url: longAudioUrl)
                        
                        
                    }
                }
            }
        }
    }
    
    public var config_id: String? {
        didSet {
            
            self.configuration = Configuration(config_id: self.config_id!)
            if let max_score=self.configuration?.JSONconfig?.experimentMaxscore {
                self.MAX_SCORE = max_score
                print("set max score ",max_score);
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
            
            if isGameOver&&playLongEffect&&GameStart {
                playLongEffect = false
                print("play haptic long effect")
//                if let hapticData = self.configuration?.hapticDataLong {
//                    self.playHaptic(hapticData: hapticData)
//                }
//                if let longAudioUrl = self.configuration?.longAudioLocalUrl {
//                    self.play(url: longAudioUrl)
//                }
            }
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
        self.setupAHAPHapticEngine()
    }
    
    func start() {
        if state.board.isMatrixEmpty { reset() }
    }
    /**
    DESCR: Initializes the LofeltHaptics Suite
    INPUT: na
    RET  : the function returns true, if it successfully intialized or false if it failed to initialize.
    **/
    func setupAHAPHapticEngine() {
        do{
            self.hapticEngine = try CHHapticEngine()
            
        } catch let error{
            print("AHAP Haptics Engine Creation Error: \(error)")
        }
        
        // Start the haptic engine for the first time.
        do {
            try self.hapticEngine?.start()
        } catch {
            print("Failed to start the engine: \(error)")
        }
        
    }
    
    
    func addNumber() {
        let result = engine.addNumber(state.board)
        state = stateTracker.updateCurrent(with: result.newBoard)
        addedTile = result.addedTile
    }
    
    var audioPlayer: AVAudioPlayer?
    func play(url: URL) {
        print("playing \(url)")

        do {

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("play audio")

        } catch let error {
            audioPlayer = nil
        }

    }
    
    
    func push(_ direction: Direction) {
    
        if(!isGameOver){
            let result = engine.push(state.board, to: direction)
            let boardHasChanged = !state.board.isEqual(result.newBoard)
            state = stateTracker.next(with: (result.newBoard, state.score + result.scoredPoints))
            if boardHasChanged {
                if(GameStart){
                    
                    if let hapticUrl = self.configuration?.shortHapticAHAPurl {
                        print("play haptic short effect")
                        self.playAHAPHaptic(hapticUrl: hapticUrl)
                    }

                    
                  if let shortAudioUrl = self.configuration?.shortAudioLocalUrl { // play short audio
                      self.play(url: shortAudioUrl)
                  }
                }
                
                addNumber()
                
                
            }
            if result.scoredPoints > 0 {
                
            }
        }
    }
    
    func playAHAPHaptic(hapticUrl: URL){
        do{
            try hapticEngine!.playPattern(from: hapticUrl)
        } catch let error {
            print("AHAP haptic engine cannot play. ", error);
        }
    }
    
    func undo() {
        state = stateTracker.undo()
    }
    
    func reset() {
        state = stateTracker.reset(with: (engine.blankBoard, .zero))
        addNumber()
        GameStart = false
        playLongEffect = true
    }
    
    func eraseBestScore() {
        bestScore = .zero
    }
    
}

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
    let instructionImage, shortEffect, longEffect, longAudio, shortAudio: URL
    enum CodingKeys: String, CodingKey {
        case instructionImage = "instruction_image"
        case shortEffect = "short_effect"
        case longEffect = "long_effect"
        case longAudio = "long_audio"
        case shortAudio = "short_audio"
    }
}



class Configuration {
    var JSONconfig: ConfigBody?
    var JSONarray: ConfigArray?
    var expidErrorJson: expidError?
    let config_id: String
    let downloadCondition: NSCondition
    private var reconnect_num=0;
    private let MAX_RETRY_NUM = 4; //changed from 2
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
    
    var shortHapticAHAPurl:URL?
    var longHapticAHAPurl:URL?
    var shortAudioLocalUrl: URL?
    var longAudioLocalUrl: URL?
    var instructionImageLocalUrl: URL?
    
    init(config_id: String) {
        self.config_id = config_id
        self.downloadCondition = NSCondition()
        //getConfig()
        self.downloadCondition.lock()
//        if (self.hapticDataShort == nil || self.hapticDataLong == nil) {
//            self.downloadCondition.wait(until: Date(timeIntervalSinceNow: 5))
//        }
    }
    
    func checkHeartbeat() {
        print("starting heartbeat call!");
        let url = URL(string: "https://3s636biw5i.execute-api.us-east-1.amazonaws.com/heartbeat")! // prod env
        var request = URLRequest(url: url)
        let bodyData = try? JSONSerialization.data(
            withJSONObject: [],
            options: []
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            let httpResponse = response as? HTTPURLResponse
            if (httpResponse?.statusCode == 200){
                print("heartbeat call was made successfully!");
            }
            else {
                //self.errorMsg = "checkHeartbeat() error!";
                print("heartbeat call error!");
            }
        }
        task.resume();
    }
    
    typealias ConfigArray = [ConfigBody]
    func getConfig(develop_env:Bool) {
        print("develop env: ",develop_env);
        var url = URL(string: "https://3s636biw5i.execute-api.us-east-1.amazonaws.com/getById")! // prod env
        if(develop_env){
            url = URL(string: "https://t8fqmzvdd7.execute-api.us-east-1.amazonaws.com/getById")! // dev env

        }
        print(url);
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
        //let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0); //use the semaphore to make the task, request JSON from server a synchronize function call
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            let httpResponse = response as? HTTPURLResponse
            print(httpResponse?.statusCode)
            if (httpResponse?.statusCode == 503){
                if(self.reconnect_num<self.MAX_RETRY_NUM){
                    print("reconnect retry request server")
                    self.reconnect_num+=1;
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.secondsToDelay) {
                        print("This message is delayed")
                        self.getConfig(develop_env: develop_env);
                    }
                }
                else {
                    self.errorMsg = "Server is Down"
                }
            }
            else if (httpResponse?.statusCode == 404){
                self.errorMsg = "Experiment id is wrong!"
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
                        
                        self.downloadContent()
                    }
                    catch {
                        print(error)
                        self.downloadCondition.signal()
                    }
                    
                } else {
                    print("experiment id is wrong")
                    self.errorMsg = "experiment id is wrong";
                    self.downloadCondition.signal()
                }
            }
            else{
                self.errorMsg = "Unkown error";
          
            }
            
        }
            
        task.resume();
        
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
                    //self.downloadContent()
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
        self.startGameButtonActive=false;
        if let url = self.JSONconfig?.linkedFiles.shortEffect {
            let downloadTaskShort = URLSession.shared.downloadTask(with: url) {
                        urlOrNil, responseOrNil, errorOrNil in
                
                if errorOrNil != nil {
                    print ("Error Downloading Short Haptic File")
                    self.startGameButtonActive=true;
                    self.errorMsg="Error Downloading Short Haptic File"
                    return
                }
                guard let location = urlOrNil else { return }
                let fileName = "short_haptic.ahap"
                
                let destination = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                do {
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    print("downloaded short haptic")
                    print("short haptic location", location)  // location dyn.ah62d4rv4ge81k5pu
                    try FileManager.default.moveItem(at: location, to: destination)
                    print("short haptic destination", destination)   // destination public.jpeg
                    self.shortHapticAHAPurl = destination
                    
                } catch {
                    print ("Error Downloading short Haptic from Aws: \(error)")
                    self.startGameButtonActive=true;
                    self.errorMsg="Error Downloading Short Haptic File"
                    
                }
            }
            downloadTaskShort.resume()
            
        } else {
            print("invalid url for short haptics file")
        }
        
        if let url = self.JSONconfig?.linkedFiles.longEffect {
            let downloadTaskLong = URLSession.shared.downloadTask(with: url) {
                urlOrNil, responseOrNil, errorOrNil in
                
                if errorOrNil != nil {
                    print ("Error Downloading Long Haptic File")
                    self.startGameButtonActive=true;
                    self.errorMsg="Error Downloading Long Haptic File"
                    return
                }
                
                guard let location = urlOrNil else { return }
                let fileName = "long_haptic.ahap"
                
                let destination = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                do {
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    print("downloaded long haptic")
                    print("long haptic location", location)  // location dyn.ah62d4rv4ge81k5pu
                    try FileManager.default.moveItem(at: location, to: destination)
                    print("long haptic destination", destination)   // destination public.jpeg
                    self.longHapticAHAPurl = destination
                    //self.startGameButtonActive=false;
                    
                } catch {
                    print ("Error Downloading Long Haptic from Aws: \(error)")
                    self.startGameButtonActive=true;
                    self.errorMsg="Error Downloading Long Haptic File"
                    
                }
            }
            downloadTaskLong.resume()
        } else {
            print("invalid url for long hapitcs file")
        }
        
        if let url = self.JSONconfig?.linkedFiles.shortAudio { // download the short audio .wav file with the right file extension
            URLSession.shared.downloadTask(with: url) { location, response, error in
                
                if error != nil {
                    self.startGameButtonActive=true
                    print("fail to download short audio file")
                    self.errorMsg="Error Downloading Short Audio File"
                    return
                }
                
                guard let location = location,
                      let httpURLResponse = response as? HTTPURLResponse,
                      httpURLResponse.statusCode == 200 else { return }
                let fileName = httpURLResponse.suggestedFilename ?? httpURLResponse.url?.lastPathComponent ?? url.lastPathComponent
                let destination = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                do {
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    print("short audio location", location)  // location dyn.ah62d4rv4ge81k5pu
                    try FileManager.default.moveItem(at: location, to: destination)
                    print("short audio destination", destination)   // destination public.jpeg
                    self.shortAudioLocalUrl=destination
                    //self.startGameButtonActive=false
                } catch {
                    self.startGameButtonActive=true
                    print("fail to download short audio file")
                    self.errorMsg="Error Downloading Short Audio File"

                }
            }.resume()
        } else {
            print("invalid url for short audio file")
        }
        
        if let url = self.JSONconfig?.linkedFiles.longAudio {
            URLSession.shared.downloadTask(with: url) { location, response, error in
                
                if error != nil {
                    self.startGameButtonActive=true
                    print("fail to download long audio file")
                    self.errorMsg="Error Downloading Long Audio File"
                    return
                }
                
                guard let location = location,
                      let httpURLResponse = response as? HTTPURLResponse,
                      httpURLResponse.statusCode == 200 else { return }
                let fileName = httpURLResponse.suggestedFilename ?? httpURLResponse.url?.lastPathComponent ?? url.lastPathComponent
                let destination = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                do {
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    print("long audio location", location)  // location dyn.ah62d4rv4ge81k5pu
                
                    try FileManager.default.moveItem(at: location, to: destination)
                    print("long audio destination", destination)   // destination public.jpeg
                    self.longAudioLocalUrl=destination
                    //self.startGameButtonActive=false
                } catch {
                    self.startGameButtonActive=true
                    print("fail to download long audio file")
                    self.errorMsg="Error Downloading Long Audio File"

                }
            }.resume()
        } else {
            print("invalid url for long audio file")
        }
        
        if let url = self.JSONconfig?.linkedFiles.instructionImage {
            let downloadTaskLong = URLSession.shared.downloadTask(with: url) {
                urlOrNil, responseOrNil, errorOrNil in
                
                if errorOrNil != nil {
                    print ("Error Downloading instruction image")
                    self.startGameButtonActive=true;
                    self.errorMsg="Error Downloading instruction image"
                    return
                }
                
                guard let location = urlOrNil else { return }
                let fileName = "instruction_image.png"
                
                let destination = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                do {
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    print("downloaded instruction image")
                    print("instruction image location", location)  // location dyn.ah62d4rv4ge81k5pu
                    try FileManager.default.moveItem(at: location, to: destination)
                    print("instruction image destination", destination)   // destination public.jpeg
                    self.instructionImageLocalUrl = destination
                    //self.startGameButtonActive=false;
                    
                } catch {
                    print ("Error Downloading instruction image from Aws: \(error)")
                    self.startGameButtonActive=true;
                    self.errorMsg="Error Downloading instruction image"
                    
                }
            }
            downloadTaskLong.resume()
        } else {
            print("invalid url for instruction image")
        }
    }
}
