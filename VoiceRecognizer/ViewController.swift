import UIKit
import Speech

class ViewController: UIViewController, AVAudioRecorderDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var lblTimer: UILabel!
    @IBOutlet weak var activityRecord: UIActivityIndicatorView!
    @IBOutlet weak var btnRec: UIButton!
    @IBOutlet weak var timeSlider: UISlider!
    
    var audioRecordingSession : AVAudioSession!
    var audioRecorder : AVAudioRecorder!
    
    let audioFileName : String = "audio-recordered.m4a"
    
    var time : Double!
    var timer : Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        time = Double(exactly: timeSlider.value.rounded())!
        lblTimer.text = time.cleanValue
        
        configureRecButton()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func recognizeSpeech() {
    
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            if authStatus == SFSpeechRecognizerAuthorizationStatus.authorized {
                
                let recognizer = SFSpeechRecognizer()
                let request = SFSpeechURLRecognitionRequest(url: self.directoryURL()!)
                
                recognizer?.recognitionTask(with: request, resultHandler: { (result, error) in
                    if let error = error {
                        print("Error recognizing audio: \(error.localizedDescription)")
                    } else {
                        if let transcribedText = result?.bestTranscription.formattedString{
                            self.textView.text = String(describing: transcribedText)
                        } else {
                            self.textView.text = "The transcribed text has not available"
                        }
                    }
                })
                
            } else {
                print("There is not authtorization to access Speech Framework")
            }
        }
    }
    
    func recordingAudioSetup() {
        audioRecordingSession = AVAudioSession.sharedInstance()
        
        do {
            try audioRecordingSession.setCategory(AVAudioSessionCategoryRecord)
            try audioRecordingSession.setActive(true)
            
            audioRecordingSession.requestRecordPermission({[unowned self] (allowed: Bool) in
                if allowed {
                    //Start the record. We have permission
                    self.startRecording()
                    
                } else {
                    print("There is no permissions to record the audio")
                }
            })
        } catch {
            print("An error has occurred configuring audio recorder")
        }
    }
    
    func directoryURL() -> URL? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL
        return documentDirectory.appendingPathComponent(audioFileName) as URL
    }
    
    func startRecording() {
        let audioSettings : [String : Any] = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 12000.0,
                        AVNumberOfChannelsKey: 1 as NSNumber,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        
        do {
            audioRecorder =  try AVAudioRecorder(url: directoryURL()!, settings: audioSettings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            btnRec.setTitle("", for: .normal)
            activityRecord.startAnimating()
            Timer.scheduledTimer(timeInterval: time, target: self, selector: #selector(self.stopRecording), userInfo: nil, repeats: false)
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateTimerLabel), userInfo: nil, repeats: true)
            
        } catch {
            print("The audio has not benn recorded correctly")
        }
    }
    
    func stopRecording() {
        audioRecorder.stop()
        audioRecorder = nil
        timer!.invalidate()
        btnRec.setTitle("REC", for: .normal)
        activityRecord.stopAnimating()
        resetTimerLabel()
        
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.recognizeSpeech), userInfo: nil, repeats: false)
    }
    
    func updateTimerLabel() {
        time! -= 1.0
        lblTimer.text = "\(time.cleanValue)"
    }
    
    func resetTimerLabel() {
        time = Double(exactly: timeSlider.value.rounded())!
        lblTimer.text = time.cleanValue
    }
    
    func configureRecButton() {
        btnRec.layer.cornerRadius = 0.5 * btnRec.bounds.size.width
        btnRec.layer.borderColor = UIColor(red:150.0/255.0, green:0-0/255.0, blue:0.0/255.0, alpha:1).cgColor
        btnRec.layer.borderWidth = 2.0
        btnRec.clipsToBounds = true
    }

    @IBAction func recButtonTapped(_ sender: UIButton) {
        textView.text = ""
        time = Double(exactly: timeSlider.value.rounded())!
        recordingAudioSetup()
    }
    @IBAction func changeSliderTimeValue(_ sender: UISlider) {
        lblTimer.text = "\(sender.value.rounded().cleanValue)"
    }
}

extension Double {
    var cleanValue: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

extension Float {
    var cleanValue: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

